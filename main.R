library("grDevices")

dataDirectory <- paste0(getwd(), "/outputLocal")
dataFile <- paste0(dataDirectory, "/data.xlsx")

outputDirectory <- paste0(getwd(), "/outputGlobal")
logFile <- paste0(outputDirectory, "/log.txt")
plotFile <- paste0(outputDirectory, "/plot.pdf")

if (!dir.exists(outputDirectory)) {
  dir.create(outputDirectory)
}
if (!dir.exists(dataDirectory)) {
  dir.create(dataDirectory)
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
