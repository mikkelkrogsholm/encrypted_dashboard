FROM ubuntu:xenial


# Ubuntu house cleaning
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  software-properties-common \
  apt-transport-https


## Install dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libbz2-1.0 \
    libcurl3 \
    libopenblas-dev \
    libpangocairo-1.0-0 \
    libpcre3 \
    libpng12-0 \
    libtiff5 \
    liblzma5 \
    locales \
    make \
    unzip \
    zip \
    zlib1g \
    curl \
    default-jdk \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre3-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    tcl8.5-dev \
    tk8.5-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    zlib1g-dev

# Install R base
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
  && add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'\
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  r-base

# Update R java conf
RUN R CMD javareconf

## Add the Tidyverse
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  libxml2-dev \
  libcairo2-dev \
  libsqlite-dev \
  libmariadbd-dev \
  libmariadb-client-lgpl-dev \
  libpq-dev \
  && Rscript -e 'install.packages(c("tidyverse", "devtools", dependencies = TRUE), repos = "https://cran.rstudio.com")'

## Add the dashboard packages
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  libssl-dev \
  libgdal1-dev \
  libproj-dev \
  && Rscript -e 'install.packages(c("rgdal", "rJava", "bcrypt", "shiny", "rmarkdown", "knitr",  "shinydashboard", "data.table", "mailR", "shinyjs", "DT", "leaflet", dependencies = TRUE), repos = "https://cran.rstudio.com")'
