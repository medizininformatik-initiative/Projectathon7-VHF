#########
# Utils #
#########

#' Check that it doesn't match any non-letter
letters_only <- function(x) !grepl("[^A-Za-z]", x)

#' @return the occurences of char c in string s
countCharInString <- function(s, c) lengths(regmatches(s, gregexpr(c, s)))

#'
#' @param dir
#' @param timeStampPrefix
#'
renameWithCreationTimeIfDirExists <- function(dir, timeStampPrefix = "") {
  newName <- NA
  if (dir.exists(dir)) {
    dirCreationTime <- as.character(file.info(dir)$ctime)
    dirCreationTime <- gsub(" ", "_", dirCreationTime)
    dirCreationTime <- gsub(":", "-", dirCreationTime)
    newName <- paste0(dir, timeStampPrefix, "_", dirCreationTime)
    file.rename(dir, newName)
  }
  return(newName)
}

#'
#' @param ...
#' @param condition
#'
createDirsRecursive <- function(..., condition = TRUE) {
  if (condition) {
    for (dir in c(...)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    }
  }
}

#' Creates a directory. If the directory already exists then a backup is
#' created. 
#'
#' @param  dir the dir to create and backp if exists
#' @param  copy If TRUE then the dir and the backup have the same content.
#' If FALSE then the new dir is empty.
#'
createDirWithBackup <- function(dir, copy = FALSE) {
  newName <- renameWithCreationTimeIfDirExists(dir, "_BAK") # NA if dir not exists
  if (copy && !is.na(newName)) {
    createDirsRecursive(dir)
    files <- list.files(newName)
    files <- paste(newName, files, sep = "/")
    file.copy(files, dir, recursive = TRUE)
  } else {
    createDirsRecursive(dir)    
  }
}

