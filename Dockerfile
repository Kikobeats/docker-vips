FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Build Args
ARG LANG="C.UTF-8"
ARG IM_VERSION=7.1.0-29
ARG LIB_HEIF_VERSION=1.12.0
ARG LIB_AOM_VERSION=3.3.0
ARG LIB_WEBP_VERSION=1.2.2
ARG LIB_VIPS_VERSION=8.12.2

RUN apt-get -y update && \
  apt-get install -y git pkg-config autoconf curl \
  # libaom
  yasm cmake \
  # libheif
  libde265-0 libde265-dev libjpeg-turbo8-dev x265 libx265-dev libtool \
  # libvips
  automake gobject-introspection gtk-doc-tools libglib2.0-dev libpng-dev libtiff5-dev libgif-dev libexif-dev libxml2-dev libxml2-utils libpoppler-glib-dev swig libpango1.0-dev libmatio-dev libopenslide-dev libcfitsio-dev libgsf-1-dev fftw3-dev liborc-0.4-dev librsvg2-dev libimagequant-dev \
  # imagemagick
  libsdl1.2-dev ghostscript libtiff-dev libfontconfig1-dev libfreetype6-dev fonts-dejavu liblcms2-dev && \
  # Building libwebp
  echo "build libwebp" && git clone -b "v$LIB_WEBP_VERSION" --single-branch --depth 1 https://chromium.googlesource.com/webm/libwebp && cd libwebp && \
  ./autogen.sh && ./configure --enable-shared --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --enable-static=no && make && make install && ldconfig && cd .. && \
  rm -rf libwebp && \
  # building libaom
  echo "build libaom" &&  git clone -b "v$LIB_AOM_VERSION" --single-branch --depth 1 https://aomedia.googlesource.com/aom && mkdir build_aom && cd build_aom && \
  cmake ../aom/ -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && make && make install && ldconfig && cd .. && \
  rm -rf aom build_aom && \
  # building libheif
  echo "build libheif" && curl -fsL https://github.com/strukturag/libheif/releases/download/v${LIB_HEIF_VERSION}/libheif-${LIB_HEIF_VERSION}.tar.gz -o libheif.tar.gz && \
  tar -xzvf libheif.tar.gz && cd libheif-${LIB_HEIF_VERSION} && \
  ./autogen.sh && ./configure && make && make install && ldconfig && cd .. && \
  rm -rf libheif-${LIB_HEIF_VERSION} libheif.tar.gz && \
  # building imagemagick
  echo "build imagemagick" && git clone -b "$IM_VERSION" --single-branch --depth 1 https://github.com/ImageMagick/ImageMagick.git && cd ImageMagick && \
  ./configure --disable-docs --disable-dependency-tracking --with-modules && make && make install && ldconfig && cd .. && \
  rm -rf ImageMagick && \
  # building libvips
  echo "build libvips" && curl -fsL https://github.com/libvips/libvips/releases/download/v${LIB_VIPS_VERSION}/vips-${LIB_VIPS_VERSION}.tar.gz -o libvips.tar.gz && \
  tar -xzvf libvips.tar.gz && cd vips-${LIB_VIPS_VERSION} && \
  ./configure --disable-dependency-tracking && make && make install && ldconfig && cd .. && \
  rm -rf vips-${LIB_VIPS_VERSION} libvips.tar.gz

# Install NodeJS
RUN curl --silent --location https://deb.nodesource.com/setup_lts.x | bash - && \
  apt-get -qq install nodejs && \
  npm install -g npm@latest

# cleanup
RUN apt-get -qq clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*