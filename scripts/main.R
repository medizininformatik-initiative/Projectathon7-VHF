###
# free memory
###
rm(list = ls())

library("grDevices")
library("fhircrackr")

dataDirectory <- paste_paths(getwd(), "outputLocal")
dataFile <- paste_paths(dataDirectory, "data.xlsx")

outputDirectory <- paste_paths(getwd(), "outputGlobal")
logFile <- paste_paths(outputDirectory, "log.txt")
plotFile <- paste_paths(outputDirectory, "plot.pdf")

if (!dir.exists(outputDirectory)) {
  dir.create(outputDirectory, recursive = T)
}

if (!dir.exists(dataDirectory)) {
  dir.create(dataDirectory, recursive = T)
}

message("start")

sink(logFile)
source(paste0(getwd(), '/retrieve.R'))

pdf(file = plotFile)
source(paste0(getwd(), "/analyze.R"))

sink()
dev.flush()
dev.off()
closeAllConnections()


# close all redirect
message("finished")
