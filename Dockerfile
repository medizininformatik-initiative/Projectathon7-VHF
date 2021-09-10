FROM registry.gitlab.com/smith-phep/polar/base:0.7

RUN Rscript -e 'install.packages("readxl", quiet = TRUE)'
RUN Rscript -e 'install.packages("writexl", quiet = TRUE)'

COPY *.R /polar/

CMD Rscript main.R
