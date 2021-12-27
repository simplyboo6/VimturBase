FROM alpine:3.15 as build

## Compile pHash
RUN apk add -U git jpeg-dev libpng-dev tiff-dev g++ make cmake libx11-dev python3 nodejs npm py3-pip

WORKDIR /build
RUN git clone https://github.com/aetilius/pHash.git && \
    git -C pHash checkout 887d07b9bdd9e2fb082c932002cefbcb1c8c20a1 && \
    sed 's|#include <sys/sysctl.h>||g' ./pHash/src/pHash.h.cmake > ./pHash/src/pHash.h.cmake.tmp && mv ./pHash/src/pHash.h.cmake.tmp ./pHash/src/pHash.h.cmake && \
    mkdir -p /build/pHash/build && cd /build/pHash/build && \
    cmake -DWITH_AUDIO_HASH=OFF -DWITH_VIDEO_HASH=OFF /build/pHash && \
    make -j8 && make install && \
    cp /build/pHash/third-party/CImg/CImg.h /usr/include/

RUN npm install --unsafe --global phash2@1.1.0
# Install latest version of gallery-dl from master that uses yt-dlp. Should be in next release post 1.19.3
RUN python3 -m pip install --no-cache-dir yt-dlp requests && \
    python3 -m pip install --no-deps --no-cache-dir https://github.com/mikf/gallery-dl/archive/master.tar.gz

FROM alpine:3.15

COPY --from=build /usr/lib/python3.9 /usr/lib/python3.9
RUN apk add --no-cache tini imagemagick jpeg libpng tiff libx11 ffmpeg nodejs yarn jpeg-dev libpng-dev tiff-dev pngquant python3

COPY --from=build /usr/bin/gallery-dl /usr/bin/yt-dlp /usr/bin/
RUN yt-dlp --version && gallery-dl --version

COPY --from=build /usr/local/lib/libpHash.so.1.0.0 /usr/local/lib/libpHash.so /usr/local/lib/
COPY --from=build /usr/local/include/pHash.h /usr/local/include/pHash.h
COPY --from=build /usr/include/CImg.h /usr/include/CImg.h
COPY --from=build /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN (cd /usr/local/lib/node_modules/phash2 && yarn link)
