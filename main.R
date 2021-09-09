library("grDevices")


thisDir <- dirname(rstudioapi::getSourceEditorContext()$path)

dataDirectory <- paste0(thisDir, "/input")
dataFile <- paste0(dataDirectory, "/data.xlsx")

outputDirectory <- paste0(thisDir, "/output")
logFile <- paste0(outputDirectory, "/log.txt")
plotFile <- paste0(outputDirectory, "/plot.pdf")

if (!dir.exists(outputDirectory)) {
  dir.create(outputDirectory)
}
if (!dir.exists(dataDirectory)) {
  dir.create(dataDirectory)
}


# https://www.rdocumentation.org/packages/utils/versions/3.6.2/topics/capture.output

message("start")

sink(logFile)
pdf(file = plotFile)
try({
  if (!file.exists(dataFile)) {
    start_time <- Sys.time()
    data_extraction_script <- paste0(thisDir, '/VHF_fhir.R')
    source(data_extraction_script)
    message("created ", dataFile, " ", format(round(Sys.time() - start_time, 2)))
  }

  source(paste0(thisDir, "/Vorhofflimmern.R"))
})


sink()
dev.flush()
dev.off()
closeAllConnections()


# close all redirect
message("finished")
