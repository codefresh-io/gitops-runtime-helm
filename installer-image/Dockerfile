# syntax=docker/dockerfile:1

# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-golang/tags/1.25-debian13-dev
FROM octopusdeploy/dhi-golang:1.25-debian13-dev@sha256:9df1a12a7a9ee811efe2929045a7eabb8617329e8ce01a3296f4af095f89522c AS build
ARG TARGETARCH
ARG CF_CLI_VERSION=v1.0.3
RUN go install github.com/davidrjonas/semver-cli@latest \
  && cp $GOPATH/bin/semver-cli /tmp/semver-cli
RUN apt-get update && apt-get install -y --no-install-recommends sed && rm -rf /var/lib/apt/lists/*
ADD --unpack=true --chown=nonroot:nonroot --chmod=755 https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz /tmp/cf/


# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-debian-base/customizations/8106437942896324135
FROM octopusdeploy/dhi-debian-base:trixie_cf-gitops-runtime-installer-debian13@sha256:5de4afaf8d55ff711756e2ebd9e27fc05374c37d3805acf85dfed70ef07fbee2 AS production
ARG TARGETARCH
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/cf/cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/semver-cli /usr/local/bin/semver-cli
COPY --from=build /usr/bin/sed /usr/bin/sed
WORKDIR /home/codefresh
USER nonroot
