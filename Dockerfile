# syntax=docker/dockerfile:experimental

FROM ubuntu:20.04

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    ca-certificates \
    curl \
    git \
    golang-go \
    python3 \
    python3-click \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir verible \
 && curl -fsSL https://github.com/google/verible/releases/download/v0.0-1213-g9e5c085/verible-v0.0-1213-g9e5c085-Ubuntu-20.04-focal-x86_64.tar.gz | tar -zxvf - -C verible --strip-components=1 \
 && for i in ./verible/bin/*; do ln -s $i /bin/$(basename $i); done

ENV GOBIN=/opt/go/bin

# Install reviewdog
RUN --mount=type=bind,src=.,target=/tmp/reviewdog \
 git clone https://github.com/reviewdog/reviewdog \
 && cd reviewdog \
 && git checkout 72c205e138df049330f2a668c33782cda55d61f6 \
 && git apply /tmp/reviewdog/reviewdog.patch \
 && mkdir -p $GOBIN \
 && go install ./cmd/reviewdog \
 && cd .. \
 && rm -rf reviewdog \
 && $GOBIN/reviewdog --version

COPY entrypoint.sh /opt/antmicro/entrypoint.sh
COPY action.py /opt/antmicro/action.py

ENTRYPOINT ["/opt/antmicro/entrypoint.sh"]
