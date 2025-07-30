{{- define "gitops-operator.default-values" }}

global:
  runtime:
    name: ''

  codefresh:
    url: ''
    tls:
      # --  Custom CA certificates bundle for platform access with ssl
      caCerts:
        # -- Reference to existing secret
        secretKeyRef: {}

replicaCount: 1

# -- Restrict the gitops operator to a single namespace (by the namespace of Helm release)
singleNamespace: false

# -- Codefresh gitops operator crds
crds:
  # -- Whether or not to install CRDs
  install: true
  # -- Keep CRDs if gitops runtime release is uninstalled
  keep: false
  # -- Annotations on gitops operator CRDs
  annotations: {}
  # -- Additional labels for gitops operator CRDs
  additionalLabels: {}

config:
  # -- Task polling interval
  taskPollingInterval: 10s
  # -- Commit status polling interval
  commitStatusPollingInterval: 10s
  # -- Workflow monitor polling interval
  workflowMonitorPollingInterval: 10s
  # -- Maximum number of concurrent releases being processed by the operator (this will not affect the number of releases being processed by the gitops runtime)
  maxConcurrentReleases: 100
  # -- An optional template for the promotion wrapper (empty default will use the embedded one)
  promotionWrapperTemplate: ''

env: {}

image:
  registry: ""
  repository: quay.io/codefresh/codefresh-gitops-operator
  # -- defaults to appVersion
  tag: ''
  pullPolicy: IfNotPresent

serviceAccount:
  create: true
  annotations: {}
  name: "gitops-operator-controller-manager"

readinessProbe:
  failureThreshold: 3
  initialDelaySeconds: 10
  periodSeconds: 10
  successThreshold: 1
  timeoutSeconds: 10

livenessProbe:
  failureThreshold: 10
  initialDelaySeconds: 10
  periodSeconds: 10
  successThreshold: 1
  timeoutSeconds: 10

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

podAnnotations: {}
podLabels: {}

podSecurityContext:
  runAsNonRoot: true
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - "ALL"
command: []
extraArgs: []
nodeSelector: {}
tolerations: []
extraVolumes: []
extraVolumeMounts: []
affinity: {}

resources:
  limits: {}
  requests:
    cpu: 100m
    memory: 128Mi

promotionTemplate:
  serviceAccount:
    create: true
    annotations: {}
    name: "promotion-template"

{{- end }}
