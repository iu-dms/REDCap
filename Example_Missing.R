source("REDCapMissingSyntax.R")

dictionary <- "MyDataDictionary.csv"
out <- "/home/MyOutputDirectory/"
forms <- c()
types <- c("calc", "descriptive", "file")
misscounter(dictionaryfile=dictionary, outpath=out, ignoreform=forms, ignoretype = types)
