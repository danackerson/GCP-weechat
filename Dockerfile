# For updates to weechat container:
# docker build . -t weechat
# docker tag <build_id_above> danackerson/weechat
# docker push danackerson/weechat
FROM alpine

ENV LANG=C.UTF-8
ENV UID=1000
ENV GID=1000

RUN BUILD_DEPS=" \
    cmake \
    build-base \
    libcurl \
    libintl \
    zlib-dev \
    curl-dev \
    perl-dev \
    gnutls-dev \
    ncurses-dev \
    libgcrypt-dev \
    ca-certificates \
    jq \
    tar" \
    && apk -U upgrade && apk add \
    ${BUILD_DEPS} \
    gnutls \
    ncurses \
    libgcrypt \
    su-exec \
    perl \
    curl \
    shadow \
    && update-ca-certificates \
    && WEECHAT_TARBALL="$(curl -sS https://api.github.com/repos/weechat/weechat/releases/latest | jq .tarball_url -r)" \
    && curl -sSL $WEECHAT_TARBALL -o /tmp/weechat.tar.gz \
    && mkdir -p /tmp/weechat/build \
    && tar xzf /tmp/weechat.tar.gz --strip 1 -C /tmp/weechat \
    && cd /tmp/weechat/build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SCRIPTS=OFF \
    -DENABLE_NLS=OFF -DENABLE_SPELL=OFF \
    #-DENABLE_PHP=OFF -DENABLE_RUBY=OFF \
    #-DENABLE_JS=OFF -DENABLE_LUA=OFF -DENABLE_TCL=OFF -DENABLE_GUILE=OFF \
    #-DENABLE_JAVASCRIPT=OFF \
    && make && make install \
    && mkdir /weechat \
    && addgroup -g $GID -S weechat \
    && adduser -u $UID -D -S -h /weechat -s /sbin/nologin -G weechat weechat \
    && usermod -o -u "$UID" weechat \
    && groupmod -o -g "$GID" weechat \
    && chown -R weechat:weechat /weechat \
    && apk del ${BUILD_DEPS} \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

EXPOSE 9001
VOLUME /weechat

USER weechat
WORKDIR /weechat

# This works perfectly with `docker run -d --name weechat -p9001:9001 weechat`
# Next try: mount the .weechat folder and pass it in during docker run!
ENTRYPOINT weechat-headless
