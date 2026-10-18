#!/bin/bash

SCRIPT_REPO="https://github.com/mstorsjo/fdk-aac.git"
SCRIPT_COMMIT="a68a51aa45d86a43c7b228e3d45624af09dcdd8d"

ffbuild_enabled() {
    [[ $VARIANT == nonfree* ]] || return -1
    return 0
}

ffbuild_dockerbuild() {
    ./autogen.sh

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --disable-shared
        --enable-static
        --with-pic
        --disable-example
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
        )
    else
        echo "Unknown target"
        return -1
    fi

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"
}

ffbuild_configure() {
    echo --enable-libfdk-aac
    
    if (( $(ffbuild_ffver) > 900 )); then
        echo --enable-libfdk-xhe-aac
    fi
}

ffbuild_unconfigure() {
    echo --disable-libfdk-aac
    
    if (( $(ffbuild_ffver) > 900 )); then
        echo --disable-libfdk-xhe-aac
    fi
}
