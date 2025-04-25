#bookworm-slim
FROM debian:12.10-slim

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

ARG CF_CLI_VERSION=v0.2.6
ARG TARGETARCH

RUN apt-get update && apt-get install curl nodejs npm -y
RUN npm install --global semver
RUN curl -L --output - https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz | tar zx && mv ./cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=bitnami/kubectl:1.32.3 /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/

RUN adduser --shell /bin/bash codefresh
USER codefresh
WORKDIR /home/codefresh
