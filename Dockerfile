FROM rocker/r-ver:latest

# MAINTAINER Julia Palm <julia.palm@med.uni-jena.de>
LABEL Description="PJT#6 smith2"
LABEL Maintainer="julia.palm@med.uni-jena.de"

RUN mkdir -p /Ergebnisse
RUN mkdir -p /errors
RUN mkdir -p /Bundles

RUN apt-get update -qq
RUN apt-get install -yqq libxml2-dev libssl-dev curl
RUN install2.r --error \
  --deps TRUE \
  fhircrackr

COPY config.R.default config.R.default
COPY smith_select.R smith_select.R
COPY install_R_packages.R install_R_packages.R

CMD ["Rscript", "smith_select.R"]
