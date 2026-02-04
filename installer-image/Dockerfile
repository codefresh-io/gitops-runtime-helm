# syntax=docker/dockerfile:1

FROM octopusdeploy/dhi-golang:1.24-alpine3.23-dev AS go-build
RUN go install github.com/davidrjonas/semver-cli@latest \
  && cp $GOPATH/bin/semver-cli /usr/local/bin/

# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-debian-base/customizations/8106437942896324135
FROM octopusdeploy/dhi-debian-base:trixie_cf-gitops-runtime-installer-debian13
ARG CF_CLI_VERSION=v0.2.16
ARG TARGETARCH
ADD --unpack=true --chown=nonroot:nonroot --chmod=755 https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz /usr/local/bin/cf
COPY --from=go-build --chown=nonroot:nonroot --chmod=755 /usr/local/bin/semver-cli /usr/local/bin/semver-cli
USER nonroot
WORKDIR /home/codefresh
