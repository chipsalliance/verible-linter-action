FROM ubuntu:20.04

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    ca-certificates \
    curl \
    git \
    golang-go \
    python3 \
    python3-click \
    python3-unidiff \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir verible \
 && curl -fsSL https://github.com/chipsalliance/verible/releases/download/v0.0-1442-g27693bd/verible-v0.0-1442-g27693bd-Ubuntu-20.04-focal-x86_64.tar.gz | tar -zxvf - -C verible --strip-components=1 \
 && for i in ./verible/bin/*; do cp $i /bin/$(basename $i); done

ENV GOBIN=/opt/go/bin

# FIXME This layer might be avoid by using BuildKit and --mount=type=bind
COPY reviewdog.patch /tmp/reviewdog/reviewdog.patch

# Install reviewdog
RUN git clone https://github.com/reviewdog/reviewdog \
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
COPY rdf_gen.py /opt/antmicro/rdf_gen.py
WORKDIR /opt/antmicro

ENTRYPOINT ["/opt/antmicro/entrypoint.sh"]
