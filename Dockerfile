FROM ubuntu:20.04

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    ca-certificates \
    curl \
    git \
    golang-go \
    jq \
    python3 \
    python3-click \
    python3-unidiff \
    wget \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir verible \
 && curl -fsSL https://api.github.com/repos/chipsalliance/verible/releases/latest | jq '.assets[] | select(.browser_download_url | test("(?=.*Ubuntu-20.04)(?=.*x86_64)")).browser_download_url' | xargs wget -qO- | tar -zxvf - -C verible --strip-components=1 \
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
