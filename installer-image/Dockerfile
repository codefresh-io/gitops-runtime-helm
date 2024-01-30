FROM --platform=$BUILDPLATFORM debian:bullseye-slim

ARG CF_CLI_VERSION=v0.1.60
ARG KUBECTL_VERSION=v1.27.2
ARG TARGETARCH

RUN apt-get update && apt-get install curl -y
RUN curl -L --output - https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz | tar zx && mv ./cf-linux-${TARGETARCH} /usr/local/bin/cf
RUN curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl && chmod +x kubectl && mv ./kubectl /usr/local/bin/kubectl

RUN adduser --shell /bin/bash codefresh
USER codefresh
WORKDIR /home/codefresh
