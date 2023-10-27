#load/install packages
packages <- c("data.table", "rmarkdown", "knitr", "dataquieR", "lubridate", "Epi", "gmodels", "xfun", "pointblank", "digest","ggplot2")

for (package in packages) {
  available <- suppressWarnings(require(package, character.only = T))
  if (!available) {
    write(paste0("Installing package ", package), stdout())
    install.packages(package, quiet = TRUE)
    packageVersion(package) # Yields an error if package not present i.e. package could not be installed
  }
}
