# syntax=docker/dockerfile:1

# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-golang/tags/1.25-debian13-dev
FROM octopusdeploy/dhi-golang:1.27-debian13-dev@sha256:a6a651898220076b5f5623fd8a4a4baef96acdd5eb45cd9f8a1a257b550891d5 AS build
ARG TARGETARCH
ARG CF_CLI_VERSION=v1.0.10
RUN go install github.com/davidrjonas/semver-cli@latest \
  && cp $GOPATH/bin/semver-cli /tmp/semver-cli
RUN apt-get update && apt-get install -y --no-install-recommends sed && rm -rf /var/lib/apt/lists/*
ADD --unpack=true --chown=nonroot:nonroot --chmod=755 https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz /tmp/cf/


# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-debian-base/customizations/8106437942896324135
FROM octopusdeploy/dhi-debian-base:trixie_cf-gitops-runtime-installer-debian13@sha256:958e36664d33a9e8cfe64f8eebf81735807b1f8a2d0563e3ba9ce696068e55c7 AS production
ARG TARGETARCH
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/cf/cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/semver-cli /usr/local/bin/semver-cli
COPY --from=build /usr/bin/sed /usr/bin/sed
WORKDIR /home/codefresh
USER nonroot
