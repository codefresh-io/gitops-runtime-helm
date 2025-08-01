{{- define "cf-argocd-extras.default-values" }}
global: {}

externalRedis:
  enabled: false
  existingSecretKeyRef:
    name: "argocd-redis"
    key: "redis-password"

eventReporter:
  fullnameOverride: event-reporter

  podAnnotations: {}

  serviceAccount:
    enabled: true

  rbac:
    enabled: true
    namespaced: false
    rules:
    - apiGroups:
      - '*'
      resources:
      - '*'
      verbs:
      - '*'
    - nonResourceURLs:
      - '*'
      verbs:
      - '*'

  controller:
    enabled: true
    type: statefulset
    replicas: 3
    revisionHistoryLimit: 5

  container:
    name: event-reporter
    image:
      registry: quay.io/codefresh
      repository: cf-argocd-extras
      tag: main
      pullPolicy: IfNotPresent

    # these do not seem to work
    ports:
    - name: metrics
      containerPort: 8087
      protocol: TCP
    - name: health
      containerPort: 8088
      protocol: TCP

    resources:
      requests:
        memory: 128Mi
        cpu: 100m

    env:
      HTTP_PROXY: '{{ .Values.global.httpProxy }}'
      HTTPS_PROXY: '{{ .Values.global.httpsProxy }}'
      NO_PROXY: '{{ .Values.global.noProxy }}'
      ARGOCD_APPLICATION_NAMESPACES:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: application.namespaces
            optional: true
      ARGOCD_SERVER:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: argocd.server
      ARGOCD_SERVER_ROOTPATH:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: server.rootpath
            optional: true
      ARGO_CD_TOKEN_SECRET_NAME: argocd-token
      ARGO_CD_TOKEN_SECRET_KEY: token
      BINARY_NAME: event-reporter
      CODEFRESH_SSL_CERT_PATH: ""
      CODEFRESH_TLS_INSECURE:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: codefresh.tls.insecure
            optional: true
      CODEFRESH_TOKEN:
        valueFrom:
          secretKeyRef:
            name: codefresh-token
            key: token
      CODEFRESH_URL:
        valueFrom:
          configMapKeyRef:
            key: base-url
            name: codefresh-cm
      EVENT_REPORTER_REPLICAS: 3
      INSECURE:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: insecure
            optional: true
      LISTEN_ADDRESS:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: listen.address
            optional: true
      LOG_FORMAT:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: log.format
            optional: true
      LOG_LEVEL:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: log.level
            optional: true
      METRICS_LISTEN_ADDRESS:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: metrics.listen.address
            optional: true
      RATE_LIMITER_BUCKET_SIZE:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: rate.limiter.bucket.size
            optional: true
      RATE_LIMITER_DURATION:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: rate.limiter.duration
            optional: true
      RATE_LIMITER_ENABLED:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: rate.limiter.enabled
            optional: true
      RATE_LIMITER_LEARNING_MODE_ENABLED:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: rate.limiter.learning.mode.enabled
            optional: true
      REDISDB:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: redis.db
            optional: true
      REDIS_COMPRESSION:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: redis.compression
            optional: true
      REDIS_PASSWORD:
        valueFrom:
          secretKeyRef:
            name: argocd-redis
            key: auth
      REDIS_SERVER:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: redis.server
      REDIS_USERNAME:
        valueFrom:
          secretKeyRef:
            name: argocd-redis
            key: redis-username
            optional: true
      REPO_SERVER:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: repo.server
      REPO_SERVER_PLAINTEXT:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: repo.server.plaintext
            optional: true
      REPO_SERVER_STRICT_TLS:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: repo.server.strict.tls
            optional: true
      REPO_SERVER_TIMEOUT_SECONDS:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: repo.server.timeout.seconds
            optional: true
      RUNTIME_VERSION:
        valueFrom:
          configMapKeyRef:
            name: codefresh-cm
            key: version
      SHARDING_ALGORITHM:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: sharding.algorithm
            optional: true
      SOURCES_SERVER:
        valueFrom:
          configMapKeyRef:
            name: event-reporter-cmd-params-cm
            key: sources.server

    volumeMounts:
      codefresh-tls-certs:
        path:
          - mountPath: /app/config/codefresh-tls-certs
            readOnly: true

    probes:
      liveness:
        enabled: true
        type: httpGet
        httpGet:
          path: /healthz?full=true
          port: 8088
        spec:
          initialDelaySeconds: 3
          periodSeconds: 30
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
      readiness:
        enabled: true
        type: httpGet
        httpGet:
          path: /healthz
          port: 8088
        spec:
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3

  configMaps:
    cmd-params-cm:
      enabled: true
      data:
        argocd.server: argo-cd-server:80
        repo.server: argo-cd-repo-server:8081
        sources.server: http://sources-server

  volumes:
    codefresh-tls-certs:
      enabled: true
      type: secret
      nameOverride: codefresh-tls-certs
      optional: true

  pdb:
    enabled: true
    minAvailable: "50%"
    maxUnavailable: ""

  service:
    main:
      enabled: true
      type: ClusterIP
      ports:
        metrics:
          port: 8087
          protocol: HTTP
          targetPort: 8087

  serviceMonitor:
    main:
      enabled: false
      endpoints:
        - port: metrics
          scheme: http
          path: /metrics
          interval: 30s
          scrapeTimeout: 10s

sourcesServer:
  fullnameOverride: sources-server

  serviceAccount:
    enabled: true

  rbac:
    enabled: true
    namespaced: false
    rules:
    - apiGroups:
      - ''
      resources:
      - configmaps
      - secrets
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - ''
      - apps
      resources:
      - deployments
      - podtemplates
      verbs:
      - patch
    - apiGroups:
      - apps
      resources:
      - replicasets
      verbs:
      - list
      - patch
    - apiGroups:
      - argoproj.io
      resources:
      - rollouts
      - rollouts/status
      verbs:
      - get
      - patch

  podAnnotations: {}

  controller:
    enabled: true
    type: deployment
    revisionHistoryLimit: 3
    deployment:
      strategy: RollingUpdate
      rollingUpdate:
        maxUnavailable: 0
        maxSurge: 50%

  hpa:
    enabled: true
    minReplicas: 1
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

  keda:
    enabled: false

  pdb:
    enabled: true
    minAvailable: "50%"
    maxUnavailable: ""

  imagePullSecrets: []

  container:
    name: sources-server
    image:
      registry: quay.io/codefresh
      repository: cf-argocd-extras
      tag: main
      pullPolicy: IfNotPresent

    ports:
    - name: server
      containerPort: 8090
      protocol: TCP

    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"

    env:
      HTTP_PROXY: '{{ .Values.global.httpProxy }}'
      HTTPS_PROXY: '{{ .Values.global.httpsProxy }}'
      NO_PROXY: '{{ .Values.global.noProxy }}'
      ARGOCD_SERVER:
        valueFrom:
          configMapKeyRef:
            name: sources-server-cmd-params-cm
            key: argocd.server
      ARGO_CD_TOKEN_SECRET_NAME: argocd-token
      ARGO_CD_TOKEN_SECRET_KEY: token
      ARGOCD_SERVER_ROOTPATH:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: server.rootpath
            optional: true
      BINARY_NAME: sources-server
      CODEFRESH_SSL_CERT_PATH: ""
      CODEFRESH_TLS_INSECURE:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: codefresh.tls.insecure
            optional: true
      CODEFRESH_TOKEN:
        valueFrom:
          secretKeyRef:
            key: token
            name: codefresh-token
      CODEFRESH_URL:
        valueFrom:
          configMapKeyRef:
            key: base-url
            name: codefresh-cm
      LISTEN_ADDRESS:
        valueFrom:
          configMapKeyRef:
            name: sources-server-cmd-params-cm
            key: server.listen.address
            optional: true
      REDISDB:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: redis.db
            optional: true
      REDIS_COMPRESSION:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: redis.compression
            optional: true
      REDIS_PASSWORD:
        valueFrom:
          secretKeyRef:
            name: argocd-redis
            key: auth
      REDIS_SERVER:
        valueFrom:
          configMapKeyRef:
            name: argocd-cmd-params-cm
            key: redis.server
      REDIS_USERNAME:
        valueFrom:
          secretKeyRef:
            name: argocd-redis
            key: redis-username
            optional: true
      REPO_SERVER:
        valueFrom:
          configMapKeyRef:
            name: sources-server-cmd-params-cm
            key: repo.server
      REPO_SERVER_TIMEOUT_SECONDS:
        valueFrom:
          configMapKeyRef:
            name: sources-server-cmd-params-cm
            key: repo.server.timeout.seconds
            optional: true

    volumeMounts:
      codefresh-tls-certs:
        path:
          - mountPath: /app/config/codefresh-tls-certs
            readOnly: true

    probes:
      liveness:
        enabled: true
        type: httpGet
        httpGet:
          path: /healthz?full=true
          port: 8090
        spec:
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
      readiness:
        enabled: true
        type: httpGet
        httpGet:
          path: /healthz
          port: 8090
        spec:
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3

  service:
    main:
      enabled: true
      primary: true
      type: ClusterIP
      ports:
        http:
          port: 80
          protocol: HTTP
          targetPort: 8090

  configMaps:
    cmd-params-cm:
      enabled: true
      data:
        argocd.server: argo-cd-server:80
        repo.server: argo-cd-repo-server:8081

  volumes:
    codefresh-tls-certs:
      enabled: true
      type: secret
      nameOverride: codefresh-tls-certs
      optional: true
{{- end }}
