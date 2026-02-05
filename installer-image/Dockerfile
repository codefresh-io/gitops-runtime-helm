# syntax=docker/dockerfile:1


FROM octopusdeploy/dhi-golang:1.25-debian13-dev AS build
ARG TARGETARCH
ARG CF_CLI_VERSION=v0.2.16
RUN go install github.com/davidrjonas/semver-cli@latest \
  && cp $GOPATH/bin/semver-cli /tmp/semver-cli
ADD --unpack=true --chown=nonroot:nonroot --chmod=755 https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz /tmp/cf/


# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-debian-base/customizations/8106437942896324135
FROM octopusdeploy/dhi-debian-base:trixie_cf-gitops-runtime-installer-debian13 AS production
ARG TARGETARCH
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/cf/cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/semver-cli /usr/local/bin/semver-cli
WORKDIR /home/codefresh
USER nonroot
