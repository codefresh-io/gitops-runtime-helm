# syntax=docker/dockerfile:1

# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-golang/tags/1.25-debian13-dev
FROM octopusdeploy/dhi-golang:1.25-debian13-dev@sha256:e6e6523b8d28c9e31354de5ecf58b849c18410b2bb7065b533066740fca549af AS build
ARG TARGETARCH
ARG CF_CLI_VERSION=v1.0.7
RUN go install github.com/davidrjonas/semver-cli@latest \
  && cp $GOPATH/bin/semver-cli /tmp/semver-cli
RUN apt-get update && apt-get install -y --no-install-recommends sed && rm -rf /var/lib/apt/lists/*
ADD --unpack=true --chown=nonroot:nonroot --chmod=755 https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz /tmp/cf/


# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-debian-base/customizations/8106437942896324135
FROM octopusdeploy/dhi-debian-base:trixie_cf-gitops-runtime-installer-debian13@sha256:5b361e78a890b74f7949f996e57b6d45043da7d70c22928868d614d2eecf48c9 AS production
ARG TARGETARCH
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/cf/cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/semver-cli /usr/local/bin/semver-cli
COPY --from=build /usr/bin/sed /usr/bin/sed
WORKDIR /home/codefresh
USER nonroot
