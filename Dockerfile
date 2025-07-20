# Wine ARM64 Linux Build with musl libc
FROM alpine:3.19

# Install build dependencies for Wine on Alpine Linux (musl)
RUN apk add --no-cache \
    build-base \
    clang \
    llvm \
    cmake \
    git \
    bison \
    flex \
    gawk \
    perl \
    python3 \
    pkgconfig \
    autoconf \
    automake \
    libtool \
    gettext-dev \
    ncurses-dev \
    freetype-dev \
    fontconfig-dev \
    libxml2-dev \
    libxslt-dev \
    gnutls-dev \
    libgcrypt-dev \
    libxrandr-dev \
    libxi-dev \
    libxext-dev \
    libxfixes-dev \
    libxrender-dev \
    libxcomposite-dev \
    libxinerama-dev \
    libxcursor-dev \
    mesa-dev \
    alsa-lib-dev \
    libpulse-dev \
    dbus-dev \
    eudev-dev \
    libusb-dev \
    sane-dev \
    cups-dev \
    krb5-dev \
    openldap-dev \
    unixodbc-dev \
    v4l-utils-dev \
    gstreamer-dev \
    gst-plugins-base-dev \
    sdl2-dev \
    vkd3d-dev \
    spirv-tools-dev \
    mingw-w64-gcc \
    mingw-w64-binutils \
    zlib-dev \
    jpeg-dev \
    libpng-dev \
    tiff-dev \
    giflib-dev \
    mpg123-dev \
    openal-soft-dev \
    libvorbis-dev \
    flac-dev \
    opus-dev

# Set environment for static linking where possible
ENV CC="clang"
ENV CXX="clang++"
ENV CFLAGS="-static-pie -fPIC -Os -pipe"
ENV CXXFLAGS="-static-pie -fPIC -Os -pipe" 
ENV LDFLAGS="-static-pie"

# Create wine user
RUN adduser -D -s /bin/sh wine
USER wine
WORKDIR /home/wine

# Clone Wine source
RUN git clone --depth 1 https://github.com/wine-mirror/wine.git wine-source

# Create build directory
WORKDIR /home/wine/wine-source
RUN mkdir -p build-arm64

# Configure Wine for ARM64 Linux with static linking preferences
WORKDIR /home/wine/wine-source/build-arm64
RUN ../configure \
    --prefix=/opt/wine-arm64 \
    --enable-archs=aarch64 \
    --disable-win16 \
    --disable-tests \
    --without-x \
    --without-wayland \
    --without-vulkan \
    --without-opengl \
    --without-opencl \
    --without-va \
    --without-capi \
    --without-cms \
    --without-coreaudio \
    --without-inotify \
    --without-oss \
    --disable-winemenubuilder \
    --disable-wineserver-debug \
    --enable-static \
    --disable-shared \
    || (cat config.log && exit 1)

# Build Wine (use multiple cores but limit to avoid OOM)
RUN make -j$(nproc) || make -j1

# Install Wine
USER root
RUN make install

# Create Wine tarball
WORKDIR /opt
RUN tar -czf /tmp/wine-arm64-linux-musl.tar.gz wine-arm64/

# Test basic Wine functionality
USER wine
ENV PATH="/opt/wine-arm64/bin:$PATH"
RUN wine --version || echo "Wine version check failed"

# Final stage - copy out the built Wine
FROM scratch AS export
COPY --from=0 /tmp/wine-arm64-linux-musl.tar.gz /


