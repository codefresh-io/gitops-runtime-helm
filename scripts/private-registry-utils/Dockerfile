FROM python:3.11.3-slim-bullseye
ARG TARGETARCH
RUN cd /tmp && python3 -c "from urllib.request import urlretrieve; urlretrieve('https://get.helm.sh/helm-v3.12.0-linux-${TARGETARCH}.tar.gz', 'helm-v3.12.0-linux-${TARGETARCH}.tar.gz')"  && tar -xvf helm-v3.12.0-linux-${TARGETARCH}.tar.gz && chmod +x linux-${TARGETARCH}/helm && mv linux-${TARGETARCH}/helm /usr/local/bin/helm && rm -rf /tmp/*
COPY charts/gitops-runtime /chart
RUN helm dependency update /chart
COPY scripts/private-registry-utils/python-requirements.txt /scripts/python-requirements.txt
RUN pip3 install -r /scripts/python-requirements.txt
COPY scripts/private-registry-utils /scripts
RUN chmod -R +x /scripts
WORKDIR /scripts
ENTRYPOINT ["bash", "docker-entrypoint.sh"]
