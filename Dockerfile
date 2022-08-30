FROM rocker/r-ver:4.2.0

LABEL Maintainer="Alexander Strübing <alexander.struebing@imise.uni-leipzig.de>"

COPY install-dependencies.* ./
RUN /bin/bash -e install-dependencies.sh

COPY config.R ./config.R
COPY main.R main.R

COPY version.txt ./

ENV OUTPUT_DIR_BASE="/mnt"

CMD ["Rscript", "main.R"]
