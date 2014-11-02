FROM rocker/rstudio

ADD install.R /tmp/install.R

RUN cd /tmp && Rscript install.R
RUN cd /tmp && rm install.R
