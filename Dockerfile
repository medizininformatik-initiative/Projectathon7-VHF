FROM registry.gitlab.com/smith-phep/polar/base:0.7

RUN Rscript -e 'install.packages("readxl", quiet = TRUE)'
RUN Rscript -e 'install.packages("xlsx", quiet = TRUE)'

COPY scripts/*.R /polar/scripts/

CMD Rscript scripts/main.R
