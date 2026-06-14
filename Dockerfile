FROM rocker/shiny:4.6.0

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages('renv', repos='https://cloud.r-project.org')"

WORKDIR /srv/shiny-server/BugSigDBAssistant

# install packages first for layer caching
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/ renv/
RUN R -e "renv::restore()"

EXPOSE 3838
