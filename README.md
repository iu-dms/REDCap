# REDCap

# 1. Missingness
### A. R Script (REDCapMissingSyntax.R)
  * This script generates a file that contains the REDCap syntax for calculated fields that count the number of missing items per form, accounting for branching logic. The script file <i>REDCapMissingSyntax.R</i> contains code that defines a function named **misscounter**, with the following 4 arguments:
    * dictionaryfile: the data dictionary CSV file for the REDCap project 
    * outpath: the filepath where you would like the syntax file to be written
    * ignoreform: vector of forms to be ignored
    * ignoretype: vector of REDCap field types to be ignored
  * See https://github.com/iu-dms/ayaniR/blob/main/ExampleFunctionCall.R for an example call of the **misscounter** function.

### B. Output file
   * output file named "missingsyntax_YYYY-MM-DD.csv" will be structured with 1 calculated field per form, and contain the necessary columns to easily add to an existing REDCap data dictionary. The field names will all begin with the prefix "missing_", which will be concatenated with the REDCap form name. These rows can then be quickly pasted into an existing REDCap data dictionary (e.g., and the last row in each form).
      *	Additionally, a second file will be exported named "expectedsyntax_YYYY-MM-DD.csv", which will contain the expected number of items (again accounting for branching logic) that are expected to have responses on each form. These fields can be added similarly as the missing items fields above, but are mainly useful outside of REDCap. For example, if added to a REDCap project, once exported with response data users could calculate the percentage completion of a form, given the expected item count and the missing item count. See the report example for these fields used to create a heatmap table of form completion.
