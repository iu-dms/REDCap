source("REDCapMissingSyntax.R")

dictionaryfile <- "MyDataDictionary.csv"
out <- "/home/MyOutputDirectory/"
forms <- c()
types <- c("calc", "descriptive", "file")
misscounter(filepath=dictionary, outpath=out, deleteforms=forms, deletetypes = types)
