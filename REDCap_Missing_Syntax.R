## ---------------------------
##
## Script name: REDCap_Missing_Syntax.R
##
## Purpose of script: Generate REDCap calculated field syntax to count the number of missing and expected responses per instrument, based on a provided 
##  REDCap data dictionary.
##
## Author: Steven Brown
##
## Organization: Indiana University Department of Biostatistics and Health Data Science
##
## Date Created: 2022-07-01
##
## Email: browstev@iu.edu
##
## ---------------------------
##
## Notes:
##  Limitations:
##    1. Will incorrectly count as missing any fields that may be intentionally left blank (e.g., checkbox fields without a "none" option)
##
## ---------------------------
## ---------------------------

### ATTACH PACKAGES ###
## Needed Package names
packages <- c("dplyr")

## Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

## Attach Packages
invisible(lapply(packages, library, character.only = TRUE))
## ---------------------------


misscounter <- function(dictionaryfile, outpath, ignoreform, ignoretype){
  
### PROCESS DATA DICTIONARY ###
## file encoding option to deal with Byte Order Mark (BOM) generated in export from REDCap (not needed if renaming as done below)
## rename columns to standard names
datadict <-  read.csv(file=dictionaryfile) %>%
  rename(field_name = 1,
         form_name = 2,
         section_header = 3,
         field_type = 4,
         field_label = 5,
         select_choices_or_calculations = 6,
         field_note = 7,
         text_validation_type_or_show_slider_number = 8,
         text_validation_min = 9,
         text_validation_max = 10,
         identifier = 11,
         branching_logic = 12,
         required_field = 13,
         custom_alignment = 14,
         question_number = 15,
         matrix_group_name = 16,
         matrix_ranking = 17,
         field_annotation = 18)

## drop unneeded variables by form and/or type 
## add running count/order (n) of variables for sorting later 
datadict2 <- datadict %>% 
  select(field_name, form_name, field_type, select_choices_or_calculations, branching_logic) %>% 
  filter( (!form_name %in% ignoreform) & (!field_type %in% ignoretype) ) %>% 
  mutate(n=row_number())

## prepare branching logic for combination with rest of equation 
datadict3 <- datadict2 %>% 
  mutate(logic2= if_else(branching_logic!="", paste0('( ', branching_logic, ' ) and'), "") ) %>% 
  rename(logic_orig=branching_logic)


## ---------------------------

### GENERATE REDCAP SYNTAX - MISSING COUNT###
## separate checkbox field types from the rest; 
checkbox <- datadict3[datadict3$field_type=="checkbox",]
othertypes <- datadict3[datadict3$field_type!="checkbox",]

## Process checkboxes- This is more complex because the multi-select variables in REDCap are referred to in the 
## format of VARIABLE(n) where VARIABLE is the name of the variable and n is the response choice, however that's 
## not the format they appear in the data dictionary

checkbox$select_choices_or_calculations <- gsub('[^|0-9,]', '', checkbox$select_choices_or_calculations)
checkbox$select_choices_or_calculations <- gsub(',[0-9]+|', '', checkbox$select_choices_or_calculations)
checkbox$select_choices_or_calculations <- gsub('[,]', '', checkbox$select_choices_or_calculations)

checkbox2 <- checkbox %>% 
  rowwise() %>% 
  mutate(chnum=list(strsplit(select_choices_or_calculations, split="|", fixed = T)) ) %>% 
  mutate(chnum2=lapply(1:length(chnum), function(x) paste('[',field_name, "(", chnum[[x]], ")] = 0", sep="")) ) %>% 
  mutate(equation1=paste0(chnum2, sep="", collapse=" and ")) %>% 
  mutate(equation=paste0('if (',logic2, ' ', equation1, ', 1, 0)'))

checkbox_ready <- checkbox2 %>% 
  select(c(n, field_name, form_name, field_type, equation))

othertypes2 <- othertypes %>% 
  mutate(equation1=paste0('([', field_name, "]= '') " )) %>% 
  mutate(equation=paste0('if (', logic2,' ', equation1, ", 1, 0)" ))

othertypes_ready <- othertypes2 %>% 
  select(c(n, field_name, form_name, field_type, equation))

miss_calc_a <- rbind(othertypes_ready, checkbox_ready) %>% 
  arrange(form_name, n) %>% 
  group_by(form_name) %>% 
  mutate(firstob=min(n)) %>% 
  mutate(lastob=max(n)) %>% 
  mutate(syntax1=if_else(n==firstob, paste0("sum( ", equation, ","),
                         if_else(n==lastob, paste0(equation, " )"), paste0(equation, ",")))) %>% 
  select(-c(n, equation, firstob, lastob))

miss_calcs_b <- miss_calc_a %>% 
  group_by(form_name) %>% 
  summarize(calculation=paste0(syntax1, collapse=" "))

miss_calcs <- miss_calcs_b %>% 
  mutate(field_name=paste0('missing_', substr(form_name,1,18))) %>% 
  mutate(section_header='Missing Response Calculation') %>% 
  mutate(field_type='calc') %>% 
  mutate(field_label=paste0('Missing Response Count for form "', form_name, '"'))

qc_fieldnames1 <- unique(miss_calcs$field_name)
if (length(qc_fieldnames1) != nrow(miss_calcs)) {
  stop("Duplicate Field Names For Missing Counts Generated - You may have to edit existing form names to prevent this from happening")
}

miss_calcs <- miss_calcs[,c(3,1,4,5,6,2)]
write.csv(miss_calcs, file=paste0(outpath, "missingsyntax_", Sys.Date(), ".csv"), row.names = F)
## ---------------------------


### GENERATE REDCAP SYNTAX - EXPECTED COUNT###
## separate questions that should always be answered (no branching logic) from those with branching logic
expect_a <- datadict3 %>% 
  filter(logic_orig=='')

expect_b <- datadict3 %>% 
  filter(logic_orig!='')

## The start_count variable will include how many questions in that form should always be answered and will be the starting point for the expected calculation
expect_a2 <- expect_a %>% 
  group_by(form_name, logic_orig) %>% 
  summarise(start_count=n()) %>% 
  mutate(expect_eq=paste0(start_count, " + sum(") )

## for fields with branching logic, determine how many fields share the same logic (i_count)
expect_b2 <- expect_b %>% 
  group_by(form_name, logic_orig) %>% 
  summarise(br_count=n()) %>% 
  mutate(expect_eq=paste0("if ((", logic_orig, "), ", br_count, " , 0) " ) )

expect_calcs_a <- rbind(expect_a2, expect_b2) %>% 
  arrange(form_name) %>% 
  mutate(n=row_number()) %>% 
  group_by(form_name) %>% 
  mutate(firstob=min(n)) %>% 
  mutate(lastob=max(n)) %>% 
  mutate(syntax1=if_else(n==firstob & n==lastob & !is.na(expect_eq), paste0(expect_eq, ")"),
                         if_else(n==firstob & !is.na(expect_eq) , expect_eq,
                                 if_else(n==lastob, paste0(expect_eq, " )"), paste0(expect_eq, ",")))))

expect_calcs_b <- expect_calcs_a %>% 
  group_by(form_name) %>% 
  summarize(calculation=paste0(syntax1, collapse=" "))

expect_calcs <- expect_calcs_b %>% 
  mutate(field_name=paste0('expect_', substr(form_name,1,18))) %>% 
  mutate(section_header='Expected Response Calculation') %>% 
  mutate(field_type='calc') %>% 
  mutate(field_label=paste0('Expected Response Count for form "', form_name, '"'))

qc_fieldnames2 <- unique(expect_calcs$field_name)
if (length(qc_fieldnames2) != nrow(expect_calcs)) {
  stop("Duplicate Field Names For Expected Counts Generated - You may have to edit existing form names to prevent this from happening")
}

expect_calcs <- expect_calcs[,c(3,1,4,5,6,2)]
write.csv(expect_calcs, file=paste0(outpath, "expectedsyntax_", Sys.Date(), ".csv"), row.names = F)

}

