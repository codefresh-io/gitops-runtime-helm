FROM --platform=$BUILDPLATFORM debian:bullseye-slim
RUN apt-get update -y && apt-get install curl wget -y
ARG CF_CLI_VERSION=v0.1.25
ARG KUBECTL_VERSION=v1.26.0
ARG TARGETARCH
RUN echo "${TARGETARCH}"
RUN wget https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz && tar -xf cf-linux-${TARGETARCH}.tar.gz && mv ./cf-linux-${TARGETARCH} /usr/local/bin/cf
RUN wget https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl && chmod +x kubectl && mv ./kubectl /usr/local/bin/kubectl
USER 1000