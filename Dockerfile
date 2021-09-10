FROM registry.gitlab.com/smith-phep/polar/base:0.7

COPY *.R /polar/

CMD Rscript main.R
