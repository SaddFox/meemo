ARG ALPINE_VERSION=3.8

FROM alpine:${ALPINE_VERSION} as builder
ARG MEEMO_VERSION=v1.9.0
RUN apk add -q --progress --update npm git python2 python-dev build-base
RUN git clone --branch ${MEEMO_VERSION} --single-branch --depth 1 https://github.com/nebulade/meemo.git /temp &> /dev/null
RUN mkdir /meemo && \
    cd /temp && \
    mv src /meemo/src && \
    mv frontend /meemo/frontend && \
    mv gulpfile.js package.json app.js things.json logo.png /meemo/
WORKDIR /meemo
RUN npm --silent install
RUN npm --silent -g install gulp
RUN gulp default

FROM alpine:${ALPINE_VERSION}
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.schema-version="1.0.0-rc1" \
      maintainer="quentin.mcgaw@gmail.com" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/qdm12/meemo" \
      org.label-schema.url="https://github.com/qdm12/meemo" \
      org.label-schema.vcs-description="Lightweight Meemo 1.9.0 server" \
      org.label-schema.vcs-usage="https://github.com/qdm12/meemo/blob/master/README.md#setup" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      org.label-schema.docker.cmd.devel="docker-compose up" \
      org.label-schema.docker.params="" \
      org.label-schema.version="" \
      image-size="115MB" \
      ram-usage="70MB" \
      cpu-usage="Low"
EXPOSE 3000/tcp
HEALTHCHECK --interval=3m --timeout=5s --start-period=20s --retries=1 \
            CMD [ "$(wget -qS -O /dev/null http://localhost:$PORT 2>&1 | grep -F HTTP | cut -d " " -f 4 | grep -o 200)" = "200"  ] || exit 1
ENV PORT=3000 \
    BIND_ADDRESS=0.0.0.0 \
    APP_ORIGIN=http://localhost \
    MONGODB_URL=mongodb://mongodb:27017/meemo \
    ATTACHMENT_DIR=/data \
    LOCAL_AUTH_FILE=/users.json \
    NODE_ENV=production
RUN apk add -q --progress --no-cache --update nodejs
COPY --from=builder /meemo/ /meemo/
USER 1000:1000
ENTRYPOINT ["node", "meemo/app.js"]
