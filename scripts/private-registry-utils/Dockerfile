FROM --platform=$BUILDPLATFORM python:3.11.3-slim-bullseye
ARG TARGETARCH
RUN cd /tmp && python3 -c "from urllib.request import urlretrieve; urlretrieve('https://get.helm.sh/helm-v3.12.0-linux-${TARGETARCH}.tar.gz', 'helm-v3.12.0-linux-${TARGETARCH}.tar.gz')"  && tar -xvf helm-v3.12.0-linux-${TARGETARCH}.tar.gz && chmod +x linux-${TARGETARCH}/helm && mv linux-${TARGETARCH}/helm /usr/local/bin/helm && rm -rf /tmp/*
COPY charts/gitops-runtime /chart
RUN helm dependency update /chart
COPY scripts/private-registry-utils/python-requirements.txt /scripts/python-requirements.txt
RUN pip3 install -r /scripts/python-requirements.txt
COPY scripts/private-registry-utils /scripts
RUN chmod -R +x /scripts
WORKDIR /scripts
# Output calculated values and filter image values
RUN ./output-calculated-values.sh ./all-values.yaml && python3 ./helper-scripts/yaml-filter.py all-values.yaml image.repository,image.registry,image.tag,argo-events.configs.nats.versions,argo-events.configs.jetstream.versions,app-proxy.image-enrichment.config.images > all-image-values.yaml
ENTRYPOINT ["python3", "private-registry-utils.py", "all-image-values.yaml"]
