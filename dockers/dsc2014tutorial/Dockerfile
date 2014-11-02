FROM rocker/rstudio

ADD install.R /tmp/install.R

RUN apt-get update && apt-get install -y libcurl4-openssl-dev libxml2-dev espeak
RUN cd /tmp && Rscript install.R
RUN cd /tmp && rm install.R
