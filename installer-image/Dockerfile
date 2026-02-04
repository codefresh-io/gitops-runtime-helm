FROM octopusdeploy/dhi-golang:1.24-alpine3.23-dev AS go-build

RUN go install github.com/davidrjonas/semver-cli@latest \
  && cp $GOPATH/bin/semver-cli /usr/local/bin/

#bookworm-slim
FROM octopusdeploy/dhi-debian-base:trixie_cf-gitops-runtime-installer-debian-13

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

ARG CF_CLI_VERSION=v0.2.16
ARG TARGETARCH

RUN curl -L --output - https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz | tar zx && mv ./cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=go-build /usr/local/bin/semver-cli /usr/local/bin/semver-cli

COPY --from=bitnamilegacy/kubectl:1.33.4 /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/

RUN useradd -m -s /bin/bash codefresh
USER codefresh
WORKDIR /home/codefresh
