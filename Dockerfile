FROM rocker/r-ver:4.2.1

LABEL Maintainer="Alexander Strübing <alexander.struebing@imise.uni-leipzig.de>"

RUN mkdir -p /Ergebnisse
RUN mkdir -p /errors
RUN mkdir -p /Bundles

RUN apt-get update -qq
RUN apt-get install -yqq libxml2-dev libssl-dev curl
RUN install2.r --error \
  --deps TRUE \
  fhircrackr

COPY config.R.default config.R.default
COPY main.R main.R
COPY install_R_packages.R install_R_packages.R

CMD ["Rscript", "main.R"]
