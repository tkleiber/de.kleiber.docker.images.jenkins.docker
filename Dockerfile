FROM alpine:3.14.3 as jre-build

RUN apk add --update --no-cache openjdk11-jdk openjdk11-jmods

# Generate smaller java runtime without unneeded files
# for now we include the full module path to maintain compatibility
# while still saving space (approx 200mb from the full distribution)
RUN jlink \
         --module-path /usr/lib/jvm/default-jvm/jmods \
         --add-modules ALL-MODULE-PATH \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /javaruntime

FROM docker

ARG VERSION=4.10
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN addgroup -g ${gid} ${group}
RUN adduser -h /home/${user} -u ${uid} -G ${group} -D ${user}
LABEL Description="This is a Docker in Docker image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="${VERSION}"

ARG AGENT_WORKDIR=/home/${user}/agent

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apk add --update --no-cache curl bash git git-lfs musl-locales openssh-client openssl procps \
  && curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar \
  && apk del --purge curl \
  && rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar* /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
COPY --from=jre-build /javaruntime $JAVA_HOME

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

LABEL \
    org.opencontainers.image.vendor="Torsten Kleiber" \
    org.opencontainers.image.title="Jenkins Docker in Docker image" \
    org.opencontainers.image.description="This is a Docker in Docker image, which provides the Jenkins agent executable (agent.jar)" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.url="https://www.amapac.io/" \
    org.opencontainers.image.source="https://github.com/tkleiber/de.kleiber.docker.images.jenkins.docker" \
    org.opencontainers.image.licenses="MIT"