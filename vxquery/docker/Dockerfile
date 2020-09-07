# "Builder" stage
FROM maven:3.6.3-openjdk-8 as builder
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

# Enables the possibility to add the following flag to docker build:
#    --build-arg MAVEN_OPTS="-Dhttp.proxyHost=proxy.ethz.ch -Dhttp.proxyPort=3128 -Dhttps.proxyHost=proxy.ethz.ch -Dhttps.proxyPort=3128"
ARG MAVEN_OPTS

RUN git clone https://github.com/apache/vxquery.git && \
    cd vxquery/ && \
    git checkout 33b3b79 && \
    mvn package -DskipTests && \
    ( \
        echo \
            ./vxquery-server/target/appassembler/bin/vxquerycc \
            ./vxquery-server/target/appassembler/bin/vxquerync \
            ./vxquery-server/target/appassembler/bin/vxqueryshutdown \
            ./vxquery-xtest/target/appassembler/bin/xtest \
            ./vxquery-cli/target/appassembler/bin/vxq \
            && \
        find . -name "*.sh" \
    ) | xargs chmod +x && \
    rm -rf ~/.m2/repository/

# Actual CLI image
FROM openjdk:8-jre-buster

COPY --from=builder /vxquery/vxquery-cli/target/appassembler/ /opt/vxquery

ENTRYPOINT ["/opt/vxquery/bin/vxq"]
