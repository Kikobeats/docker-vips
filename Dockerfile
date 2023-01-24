FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

ARG IM_VERSION=7.1.0-58
ARG LIB_HEIF_VERSION=1.14.2
ARG LIB_AOM_VERSION=3.5.0
ARG LIB_WEBP_VERSION=1.3.0
ARG LIB_VIPS_VERSION=8.14.1

ENV LANG="C.UTF-8"
ENV CC=clang 
ENV CXX=clang++

# install dependencies
RUN apt-get -y update && \
  apt-get -y upgrade && \
  apt-get install -y git curl clang \
  # libaom
  yasm cmake \
  # libheif
  libde265-0 libde265-dev libjpeg-turbo8-dev x265 libx265-dev libtool \
  # libwebp
  libsdl1.2-dev libgif-dev \
  # imagemagick
  fonts-dejavu ghostscript libfontconfig1-dev libfreetype6-dev libgomp1 liblcms2-dev libpng-dev libpng16-16 libtiff-dev libxml2-dev libxml2-utils \
  # libvips
  # https://github.com/libvips/libvips/wiki/Build-for-Ubuntu
  automake libgirepository1.0-dev gtk-doc-tools libexpat1-dev libfftw3-dev libglib2.0-dev libgif-dev libgsf-1-dev libmagickwand-dev libmatio-dev libopenexr-dev libopenslide-dev liborc-0.4-dev swig \
  libexif-dev libtiff5-dev libcfitsio-dev libpoppler-glib-dev librsvg2-dev libpango1.0-dev libffi-dev libopenjp2-7-dev libimagequant-dev \
  python3-pip bc && pip3 install meson

# building libwebp
RUN echo "build libwebp" && git clone -b "v$LIB_WEBP_VERSION" --single-branch --depth 1 https://chromium.googlesource.com/webm/libwebp && cd libwebp && \
  ./autogen.sh && ./configure --enable-shared --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --enable-static=no && make -j$(nproc) && make install && ldconfig && cd .. && \
  rm -rf libwebp

# building libaom
RUN echo "build libaom" &&  git clone -b "v$LIB_AOM_VERSION" --single-branch --depth 1 https://aomedia.googlesource.com/aom && mkdir build_aom && cd build_aom && \
  cmake ../aom/ -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && make -j$(nproc) && make install && ldconfig && cd .. && \
  rm -rf aom build_aom

# building libheif
RUN echo "build libheif" && curl -fsL https://github.com/strukturag/libheif/releases/download/v${LIB_HEIF_VERSION}/libheif-${LIB_HEIF_VERSION}.tar.gz -o libheif.tar.gz && \
  tar -xzvf libheif.tar.gz && cd libheif-${LIB_HEIF_VERSION} && \
  ./autogen.sh && ./configure && make -j$(nproc) && make install && ldconfig && cd .. && \
  rm -rf libheif-${LIB_HEIF_VERSION} libheif.tar.gz

# building imagemagick
RUN echo "build imagemagick" && git clone -b "$IM_VERSION" --single-branch --depth 1 https://github.com/ImageMagick/ImageMagick.git && cd ImageMagick && \
  ./configure --without-magick-plus-plus --enable-static --disable-docs --disable-dependency-tracking --with-modules && make -j$(nproc) && make install && ldconfig && cd .. && \
  rm -rf ImageMagick

# building libvips
RUN echo "build libvips" && curl -fsL https://github.com/libvips/libvips/releases/download/v${LIB_VIPS_VERSION}/vips-${LIB_VIPS_VERSION}.tar.xz -o libvips.tar.xz && \
  tar -xvf libvips.tar.xz && cd vips-${LIB_VIPS_VERSION} && \
  meson build --libdir=lib --buildtype=release -Dintrospection=false && \
  cd build && meson compile && meson test && meson install && cd ../.. && \
  rm -rf vips-${LIB_VIPS_VERSION} libvips.tar.xz

# Install NodeJS
RUN curl --silent --location https://deb.nodesource.com/setup_lts.x | bash - && \
  apt-get -qq install nodejs && \
  npm install -g npm@latest

# cleanup
RUN pip3 uninstall -y meson && apt-get remove --autoremove --purge -y curl gtk-doc-tools libfontconfig1-dev libfreetype6-dev libgif-dev libgirepository1.0-dev libsdl1.2-dev libtiff5-dev libtool libxml2-utils swig yasm python3-pip bc
RUN apt-get -qq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
