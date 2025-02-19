#bullseye-slim
FROM debian:11.10-slim

ARG CF_CLI_VERSION=v0.1.70
ARG TARGETARCH

RUN apt-get update && apt-get install curl -y
RUN curl -L --output - https://github.com/codefresh-io/cli-v2/releases/download/${CF_CLI_VERSION}/cf-linux-${TARGETARCH}.tar.gz | tar zx && mv ./cf-linux-${TARGETARCH} /usr/local/bin/cf
COPY --from=bitnami/kubectl:1.32.1 /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/

RUN adduser --shell /bin/bash codefresh
USER codefresh
WORKDIR /home/codefresh