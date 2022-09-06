FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

ARG LANG="C.UTF-8"
ARG IM_VERSION=7.1.0-47
ARG LIB_HEIF_VERSION=1.13.0
ARG LIB_AOM_VERSION=3.4.0
ARG LIB_WEBP_VERSION=1.2.4
ARG LIB_VIPS_VERSION=8.12.2

# install dependencies
RUN apt-get -y update && \
  apt-get -y upgrade && \
  apt-get install -y git curl \
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
  automake gobject-introspection gtk-doc-tools libexpat1-dev libfftw3-dev libglib2.0-dev libgif-dev libgsf-1-dev libmagickwand-dev libmatio-dev libopenexr-dev libopenslide-dev liborc-0.4-dev swig \
  libexif-dev libtiff5-dev libcfitsio-dev libpoppler-glib-dev librsvg2-dev libpango1.0-dev libffi-dev libopenjp2-7-dev libimagequant-dev

# building libwebp
RUN echo "build libwebp" && git clone -b "v$LIB_WEBP_VERSION" --single-branch --depth 1 https://chromium.googlesource.com/webm/libwebp && cd libwebp && \
  ./autogen.sh && ./configure --enable-shared --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --enable-static=no && make && make install && ldconfig && cd .. && \
  rm -rf libwebp

# building libaom
RUN echo "build libaom" &&  git clone -b "v$LIB_AOM_VERSION" --single-branch --depth 1 https://aomedia.googlesource.com/aom && mkdir build_aom && cd build_aom && \
  cmake ../aom/ -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && make && make install && ldconfig && cd .. && \
  rm -rf aom build_aom

# building libheif
RUN echo "build libheif" && curl -fsL https://github.com/strukturag/libheif/releases/download/v${LIB_HEIF_VERSION}/libheif-${LIB_HEIF_VERSION}.tar.gz -o libheif.tar.gz && \
  tar -xzvf libheif.tar.gz && cd libheif-${LIB_HEIF_VERSION} && \
  ./autogen.sh && ./configure && make && make install && ldconfig && cd .. && \
  rm -rf libheif-${LIB_HEIF_VERSION} libheif.tar.gz

# building imagemagick
RUN echo "build imagemagick" && git clone -b "$IM_VERSION" --single-branch --depth 1 https://github.com/ImageMagick/ImageMagick.git && cd ImageMagick && \
  ./configure --without-magick-plus-plus --disable-static --disable-docs --disable-dependency-tracking --with-modules && make && make install && ldconfig && cd .. && \
  rm -rf ImageMagick

# building libvips
RUN echo "build libvips" && curl -fsL https://github.com/libvips/libvips/releases/download/v${LIB_VIPS_VERSION}/vips-${LIB_VIPS_VERSION}.tar.gz -o libvips.tar.gz && \
  tar -xzvf libvips.tar.gz && cd vips-${LIB_VIPS_VERSION} && \
  ./configure && make && make install && ldconfig && cd .. && \
  rm -rf vips-${LIB_VIPS_VERSION} libvips.tar.gz

# Install NodeJS
RUN curl --silent --location https://deb.nodesource.com/setup_lts.x | bash - && \
  apt-get -qq install nodejs && \
  npm install -g npm@latest

# cleanup
RUN apt-get -qq clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*