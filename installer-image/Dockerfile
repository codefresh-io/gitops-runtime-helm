# syntax=docker/dockerfile:1

# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-golang/tags/1.25-debian13-dev
FROM octopusdeploy/dhi-golang:1.27-debian13-dev@sha256:1a1525863730c4f72323b521df75bb51ac9278d5a2c7e4978dc2884ed4b62439 AS build
ARG TARGETARCH
ARG CF_CLI_VERSION=v1.0.10
RUN go install github.com/davidrjonas/semver-cli@latest \
  && cp $GOPATH/bin/semver-cli /tmp/semver-cli
RUN apt-get update && apt-get install -y --no-install-recommends sed && rm -rf /var/lib/apt/lists/*
ADD --unpack=true --chown=nonroot:nonroot --chmod=755 https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz /tmp/cf/


# DHI source: https://hub.docker.com/repository/docker/octopusdeploy/dhi-debian-base/customizations/8106437942896324135
FROM octopusdeploy/dhi-debian-base:trixie_cf-gitops-runtime-installer-debian13@sha256:3351264ab683af6211966287085460a0ec0d37ac27515d06b9f739dfdd3b1056 AS production
ARG TARGETARCH
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/cf/cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=build --chown=nonroot:nonroot --chmod=755 /tmp/semver-cli /usr/local/bin/semver-cli
COPY --from=build /usr/bin/sed /usr/bin/sed
WORKDIR /home/codefresh
USER nonroot
