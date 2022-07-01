packages <- c("fhircrackr", "data.table")

for(package in packages){
    available <- suppressWarnings(require(package, character.only = T))
    if(!available){
        write(paste0("Installing package ", package), stdout())
        install.packages(package, quiet = TRUE)
        packageVersion(package) # Yields an error if package not present i.e. package could not be installed
    }
}
