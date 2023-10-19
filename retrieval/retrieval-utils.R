###########################################
# Utils especially for the retrieval part #
###########################################

#'
#' @param dateStringWithLeadingYear a string representing a date or only a year. The year must be the
#' first 4 characters of the string.
#' @return the extracted year from the given date string
#'
getYear <- function(dateStringWithLeadingYear) {
  date <- as.POSIXct(as.character(dateStringWithLeadingYear), format = "%Y")
  return (year(date))
}

####################################
# Absolute to Relative ID Function #
####################################

#'
#' @param references single string or list of strings
#' @return single string or list of strings where only the last part of each string
#' remains after a slash '/'. Strings without slashes are returned unchanged.
#'
makeRelative <- function(references) {
  return(gsub(".*/", "", references))
}
