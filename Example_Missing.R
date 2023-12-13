source("redcap_missing_syntax.R")

dictionaryfile <- "MyDataDictionary.csv"
out <- "/home/MyOutputDirectory/"
forms <- c()
types <- c("calc", "descriptive", "file")
misscounter(dictionaryfile=dictionary, outpath=out, ignoreform=forms, ignoretype = types)
