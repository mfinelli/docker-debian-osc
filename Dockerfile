ARG OSC_VERSION=1.5.1

FROM debian:bookworm as base
WORKDIR /osc

RUN groupadd --gid 1000 osc && \
  useradd --uid 1000 --gid osc --shell /bin/bash --create-home osc

RUN apt-get update

FROM base as downloader

ARG OSC_VERSION
ENV OSC_VERSION=$OSC_VERSION
ENV OSC_URLBASE=https://github.com/openSUSE/osc

RUN \
  apt-get install -y curl && \
  curl -fsSLo osc.tar.gz \
    ${OSC_URLBASE}/archive/refs/tags/${OSC_VERSION}.tar.gz && \
  tar xzvf osc.tar.gz --strip-components=1 && \
  rm osc.tar.gz

FROM base as builder

RUN apt-get install -y \
  python3-cryptography \
  python3-rpm \
  python3-setuptools \
  python3-urllib3

COPY --from=downloader /osc /usr/src/osc

RUN \
  cd /usr/src/osc && \
  ./setup.py build && \
  ./setup.py install

FROM base

LABEL org.opencontainers.image.source \
  https://github.com/mfinelli/docker-debian-osc

RUN apt-get install -y \
  ca-certificates \
  python3-cryptography \
  python3-rpm \
  python3-urllib3 && \
  rm -rf /var/lib/apt/lists/* && \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

COPY --from=downloader /osc /usr/src/osc
COPY --from=builder /usr/local /usr/local

USER 1000
