#########################################################
# The retrieval script and the analysis script only
# work if the working directory of R is the subfolder 
# "/retrieval" and "/analysis" respectively.
# Therefore, when executing the scripts manually,
# you must first change to the specific R working
# directory.
#########################################################

# gets the current working directory as base working 
# directory
# (this should be the directory of this script!)
working_dir <- getwd()

# The base working directory is shared with the retrieval
# and analysis scripts via the system environment.
# This directory contains the output folders after the
# script execution.
Sys.setenv("OUTPUT_DIR_BASE" = getwd())

# changes the current working directory to the retrieval
# subfolder and runs the retrieval script
setwd(paste0(working_dir, "/retrieval"))
source("main.R")

# changes the current working directory to the analysis
# subfolder and runs the analysis script
setwd(paste0(working_dir, "/analysis"))
source("main.R")
