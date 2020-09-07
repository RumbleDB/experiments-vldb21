FROM debian:buster
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget --progress=dot:giga -O /tmp/xidel.deb \
        https://sourceforge.net/projects/videlibri/files/Xidel/Xidel%200.9.8/xidel_0.9.8-1_amd64.deb/download && \
    dpkg -i /tmp/xidel.deb && \
    rm /tmp/xidel.deb

COPY entrypoint.sh /opt/bin/entrypoint.sh

ENTRYPOINT ["/opt/bin/entrypoint.sh"]
