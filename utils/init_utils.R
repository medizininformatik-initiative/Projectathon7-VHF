
#####################################################################
### Copy this file into the root of your utils directory and run: ###
### source('../utils/init_utils.R')                               ###
#####################################################################

#'
#' Source all R scripts in a directory and its subdirectories.
#'
#' This function sources all R scripts in the specified directory and, if
#' source_subdirs is set to TRUE, in its subdirectories as well, using the source() function.
#'
#' @param script_path The path to the directory containing R scripts.
#' @param source_subdirs Logical, indicating whether to source scripts in subdirectories (default is TRUE).
#'
#' @examples
#' # Source all R scripts in the current directory and its subdirectories
#' sourceScripts("/path/to/directory", source_subdirs = TRUE)
#'
#' @export
sourceScripts <- function(script_path, recursive = TRUE) {
  # Get the path to this script
  this.path <- paste0(utils::getSrcDirectory(sourceScripts), '/', getSrcFilename(sourceScripts))
  # List all R files with relative paths
  script_files <- list.files(path = script_path, pattern = "\\.R$", recursive = recursive, full.names = TRUE)
  # Run all R files
  for (script_file in script_files) {
    # exclude this script from sourcing
    if (script_file != this.path) {
      source(script_file)
    }
  }
}

# sources all files in the dir of this script and all subdirs
sourceScripts(utils::getSrcDirectory(sourceScripts))
