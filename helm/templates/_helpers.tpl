{{/*
Expand the name of the chart.
*/}}
{{- define "fbcore.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully-qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fbcore.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fbcore.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "fbcore.labels" -}}
{{ include "fbcore.selectorLabels" . }}
helm.sh/chart: {{ include "fbcore.chart" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.extraLabels }}
{{- toYaml .Values.extraLabels | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fbcore.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fbcore.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common service ports for Firebolt Core
*/}}
{{- define "fbcore.servicePorts" -}}
- name: http-query
  port: 3473
  protocol: TCP
- name: health
  port: 8122
  protocol: TCP
- name: execp
  port: 5678
  protocol: TCP
- name: datacp
  port: 16000
  protocol: TCP
- name: storage-manager
  port: 1717
  protocol: TCP
- name: storage-agent
  port: 3434
  protocol: TCP
- name: metadata
  port: 6500
  protocol: TCP
- name: metrics
  port: 9090
  protocol: TCP
{{- end }}

{{/*
PVC prefix - used for volume naming in both StatefulSet and Deployment modes.
Returns pvcPrefixOverride if set, otherwise defaults to fullname-data.
*/}}
{{- define "fbcore.pvc_prefix" -}}
{{- if .Values.pvcPrefixOverride -}}
{{- .Values.pvcPrefixOverride -}}
{{- else -}}
{{- include "fbcore.fullname" . }}-data
{{- end -}}
{{- end -}}

{{/*
Memlock setup sidecar script - loaded from files/memlock-setup.sh
*/}}
{{- define "fbcore.memlockSetupScript" -}}
{{ .Files.Get "files/memlock-setup.sh" }}
{{- end }}
