ARG GH_REPO=ghcr.io/btbn/ffmpeg-builds
ARG BASE_TAG_SUFFIX=
FROM $GH_REPO/base:latest${BASE_TAG_SUFFIX}

RUN --mount=src=ct-ng-config,dst=/.config \
    git clone --filter=blob:none https://github.com/crosstool-ng/crosstool-ng.git /ct-ng && cd /ct-ng && \
    ./bootstrap && \
    ./configure --enable-local && \
    make -j$(nproc) && \
    cp /.config .config && \
    ./ct-ng build && \
    cd / && \
    rm -rf ct-ng

# Prepare "cross" environment to heavily favour static builds
RUN \
    find /opt/ct-ng \( \
        -name "*.dll" \
        -or -name "*.dll.a" \
        \) -delete && \
    mkdir /opt/ffbuild

RUN \
    apt-get -y update && \
    apt-get -y install --no-install-recommends wine && \
    apt-get -y clean autoclean && \
    rm -rf /var/lib/apt/lists/*

ENV FFBUILD_TOOLCHAIN=x86_64-w64-mingw32 \
    FFBUILD_RUST_TARGET=x86_64-pc-windows-gnu

RUN \
    rustup target add "$FFBUILD_RUST_TARGET" && \
    echo "[target.$FFBUILD_RUST_TARGET]\nlinker = \"${FFBUILD_TOOLCHAIN}-gcc\"\nar = \"${FFBUILD_TOOLCHAIN}-gcc-ar\"\n" > "$CARGO_HOME"/config.toml

ADD toolchain.cmake /toolchain.cmake
ADD cross.meson /cross.meson

ENV PATH="/opt/ct-ng/bin:${PATH}" \
    FFBUILD_TARGET_FLAGS="--pkg-config=pkg-config --cross-prefix=${FFBUILD_TOOLCHAIN}- --arch=x86_64 --target-os=mingw32" \
    FFBUILD_CROSS_PREFIX=${FFBUILD_TOOLCHAIN}- \
    FFBUILD_PREFIX=/opt/ffbuild \
    FFBUILD_DESTDIR=/opt/ffdest \
    FFBUILD_DESTPREFIX=/opt/ffdest/opt/ffbuild \
    FFBUILD_CMAKE_TOOLCHAIN=/toolchain.cmake \
    prefix=/ffbuild/prefix \
    cross_prefix=${FFBUILD_TOOLCHAIN}- \
    arch=x86_64 \
    target_os=mingw32 \
    pkg_config=pkg-config \
    PKG_CONFIG=pkg-config \
    PKG_CONFIG_LIBDIR=/opt/ffbuild/lib/pkgconfig:/opt/ffbuild/share/pkgconfig \
    cc="${FFBUILD_TOOLCHAIN}-gcc" \
    cxx="${FFBUILD_TOOLCHAIN}-g++" \
    ld="${FFBUILD_TOOLCHAIN}-ld" \
    ar="${FFBUILD_TOOLCHAIN}-gcc-ar" \
    ranlib="${FFBUILD_TOOLCHAIN}-gcc-ranlib" \
    nm="${FFBUILD_TOOLCHAIN}-gcc-nm" \
    CC="${FFBUILD_TOOLCHAIN}-gcc" \
    CXX="${FFBUILD_TOOLCHAIN}-g++" \
    LD="${FFBUILD_TOOLCHAIN}-ld" \
    AR="${FFBUILD_TOOLCHAIN}-gcc-ar" \
    RANLIB="${FFBUILD_TOOLCHAIN}-gcc-ranlib" \
    NM="${FFBUILD_TOOLCHAIN}-gcc-nm" \
