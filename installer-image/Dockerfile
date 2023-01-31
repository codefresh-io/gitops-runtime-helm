FROM --platform=$BUILDPLATFORM debian:bullseye-slim
RUN apt-get update -y && apt-get install curl -y
ARG CF_CLI_VERSION=v0.1.25
ARG KUBECTL_VERSION=v1.26.0
ARG ARGOCD_VERSION=v2.4.15
ARG TARGETARCH
RUN echo "${TARGETARCH}"
RUN curl -L --output - https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz | tar zx && mv ./cf-linux-${TARGETARCH} /usr/local/bin/cf
RUN curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl && chmod +x kubectl && mv ./kubectl /usr/local/bin/kubectl
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${TARGETARCH} && chmod +x /usr/local/bin/argocd 