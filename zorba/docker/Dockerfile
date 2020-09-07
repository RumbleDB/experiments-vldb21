FROM ubuntu:12.04
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python-software-properties && \
    add-apt-repository -y ppa:juan457/zorba && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        zorba \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["zorba"]
