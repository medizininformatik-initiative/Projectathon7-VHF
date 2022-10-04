working_dir <- getwd()

Sys.setenv("OUTPUT_DIR_BASE" = getwd())

setwd(paste0(working_dir, "/retrieval"))
source("main.R")

setwd(paste0(working_dir, "/analysis"))
source("main.R")
