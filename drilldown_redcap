# Create REDCap branching logic for drill down questions
# by: Adam Rector
# created 9/1/2021
# last updated 9/16/2021

library(tidyverse)

# read in the first tier selection data
tier1_codes <- read.csv(file = 'tier1.csv')

## combine the tier 1 codes

tier1_codes$tier1 <- paste(tier1_codes$tier1_id, tier1_codes$tier1_name, sep=", ")

tier1_codes <- tier1_codes %>%
  select(tier1)

## make the long data set wide instead, formatting as necessary for the eventual REDCap export

tier1 <- tier1_codes %>%
  summarise(tier1 = paste(tier1, collapse=" | "))%>%
  rename(choices=tier1)


# read in the second tier selection data
tier2_codes <- read.csv(file = 'tier2.csv')

# combine the tier 2 codes

tier2_codes$tier2 <- paste(tier2_codes$tier2_id, tier2_codes$tier2_name, sep=", ")

tier2_codes <- tier2_codes %>%
  select(tier1_id, tier2)

# make the long data set wide instead, formatting as necessary for the eventual REDCap export

tier2_by_tier1 <- tier2_codes %>%
  group_by(tier1_id) %>% summarise(tier2 = paste(tier2, collapse=" | ")) %>%
  rename(tier1=tier1_id)


## create the format for the final data frame as a REDCap instrument

#first column, variable
redcap_instr <- tier2_by_tier1 %>%
  select(tier1)
redcap_instr$tier1 <- formatC(redcap_instr$tier1, width = 4, format = "d", flag = "0")
redcap_instr$tier1 <- paste("tier2_", redcap_instr$tier1, sep="")
redcap_instr <- redcap_instr %>%
  rename(variable=tier1)

#second column, form name
redcap_instr$form <- "drilldown"

#third column, section header
redcap_instr$header <- ""

#fourth column, field type
redcap_instr$fieldtype <- "dropdown"

#fifth column, field label
redcap_instr$label <- "Please select your second option from the list:"

#sixth column, choices
redcap_instr$choices <- tier2_by_tier1$tier2

#seventh column, field note
redcap_instr$note <- "Begin typing to search list"

#eight column, text validation type
redcap_instr$validate <- "autocomplete"

#ninth column, validation min
redcap_instr$min <- ""

#tenth column, validation max
redcap_instr$max <- ""

#eleventh column, identifier
redcap_instr$ident <- ""

#twelfth column, branching logic
redcap_instr$branch <- paste("[tier1_choice] = '", formatC(tier2_by_tier1$tier1, width = 4, format = "d", flag = "0"), "'", sep="")

#thirteenth column, required
redcap_instr$required <- "y"

#fourteenth column, alignment
redcap_instr$align <- ""

#fifteenth column, question number
redcap_instr$questnum <- ""

#sixteenth column, matrix group
redcap_instr$matrixgroup <- ""

#seventeenth column, matrix rank
redcap_instr$matrixrank <- ""

#eighteenth column, field annotation
redcap_instr$annotat <- ""



# bind the initial variable to the top of the redcap instrument dataframe
redcap_instr2 <- rbind(data.frame(variable = "tier1_choice", form = "drilldown", header="", fieldtype="dropdown", label="Please select your first option from the list:", choices=tier1, note="Begin typing to search list", validate="autocomplete", min="", max="", ident="", branch="", required="y", align="", questnum="", matrixgroup="", matrixrank="", annotat=""), redcap_instr)


# export the data as a csv instrument
write.csv(redcap_instr2,"instrument.csv", row.names = FALSE)

# zip the csv for upload to REDCap
zip("dropdown.zip", "instrument.csv")

