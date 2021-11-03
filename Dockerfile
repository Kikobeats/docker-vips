FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

ARG IM_VERSION=7.1.0-10
ARG LIB_HEIF_VERSION=1.12.0
ARG LIB_AOM_VERSION=3.2.0
ARG LIB_WEBP_VERSION=1.2.1
ARG BLESS_USER_ID=999

COPY fonts.conf /etc/fonts/local.conf

# Dependencies + NodeJS
RUN apt-get -qq update && \
  echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
  apt-get -y -qq install software-properties-common &&\
  apt-add-repository "deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner" && \
  apt-get -qq update && apt-get -y -qq --no-install-recommends install \
  dumb-init \
  git \
  ffmpeg \
  fonts-liberation \
  msttcorefonts \
  fonts-roboto \
  fonts-ubuntu \
  fonts-noto-color-emoji \
  fonts-noto-cjk \
  fonts-ipafont-gothic \
  fonts-wqy-zenhei \
  fonts-kacst \
  fonts-freefont-ttf \
  fonts-thai-tlwg \
  fonts-indic \
  fontconfig \
  libappindicator3-1 \
  pdftk \
  unzip \
  locales \
  gconf-service \
  libasound2 \
  libatk1.0-0 \
  libc6 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgcc1 \
  libgconf-2-4 \
  libgdk-pixbuf2.0-0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libstdc++6 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  libllvm8 \
  libgbm-dev \
  ca-certificates \
  libappindicator1 \
  libnss3 \
  lsb-release \
  xdg-utils \
  wget \
  xvfb \
  curl

# Only install Adobe Flash  on amd64 (not available for other architectures)
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then apt-get -qq --no-install-recommends install adobe-flashplugin; fi

# imagemagick + vips
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install -y git make gcc pkg-config autoconf curl g++ \
    # libaom
    yasm cmake \
    # libheif
    libde265-0 libde265-dev libjpeg-turbo8 libjpeg-turbo8-dev x265 libx265-dev libtool \
    # IM
    libpng16-16 libpng-dev libjpeg-turbo8 libjpeg-turbo8-dev libgomp1 ghostscript libxml2-dev libxml2-utils libtiff-dev libfontconfig1-dev libfreetype6-dev && \
    # Building libwebp
    git clone https://chromium.googlesource.com/webm/libwebp && \
    cd libwebp && git checkout v${LIB_WEBP_VERSION} && \
    ./autogen.sh && ./configure --enable-shared --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --enable-static=no && \
    make && make install && \
    ldconfig /usr/local/lib && \
    cd ../ && rm -rf libwebp && \
    # Building libaom
    git clone https://aomedia.googlesource.com/aom && \
    cd aom && git checkout v${LIB_AOM_VERSION} && cd .. && \
    mkdir build_aom && \
    cd build_aom && \
    cmake ../aom/ -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && make && make install && \
    ldconfig /usr/local/lib && \
    cd .. && \
    rm -rf aom && \
    rm -rf build_aom && \
    # Building libheif
    curl -L https://github.com/strukturag/libheif/releases/download/v${LIB_HEIF_VERSION}/libheif-${LIB_HEIF_VERSION}.tar.gz -o libheif.tar.gz && \
    tar -xzvf libheif.tar.gz && cd libheif-${LIB_HEIF_VERSION}/ && ./autogen.sh && ./configure && make && make install && cd .. && \
    ldconfig /usr/local/lib && \
    rm -rf libheif-${LIB_HEIF_VERSION} && rm libheif.tar.gz && \
    # Building ImageMagick
    git clone https://github.com/ImageMagick/ImageMagick.git && \
    cd ImageMagick && git checkout ${IM_VERSION} && \
    ./configure --without-magick-plus-plus --disable-docs --disable-static --with-libtiff && \
    make && make install && \
    ldconfig /usr/local/lib && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /ImageMagick

# More dependencies + NodeJS + cleanup
RUN  curl --silent --location https://deb.nodesource.com/setup_16.x | bash - &&\
  apt-get -qq install nodejs &&\
  apt-get -qq install build-essential &&\
  fc-cache -f -v &&\
  apt-get -qq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add the browserless user (blessuser)
RUN groupadd -r blessuser && useradd --uid ${BLESS_USER_ID} -r -g blessuser -G audio,video blessuser \
  && mkdir -p /home/blessuser/Downloads \
  && chown -R blessuser:blessuser /home/blessuser

# Install deps necessary to build
RUN npm install -g typescript @types/node