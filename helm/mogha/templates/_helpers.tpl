{{/*
Create the kind for role. Will be Role in single
namespace mode or ClusterRole by default.
*/}}
{{- define "install.roleKind" -}}
{{- if .Values.singleNamespace -}}
Role
{{- else -}}
ClusterRole
{{- end }}
{{- end }}

{{/*
role name
*/}}
{{- define "install.roleName" }}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
service account name
*/}}
{{- define "install.serviceAccountName" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
role binding name
*/}}
{{- define "install.roleBindingName" }}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
service name
*/}}
{{- define "install.serviceName" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the kind for rolebindings. Will be RoleBinding in single
namespace mode or ClusterRoleBinding by default.
*/}}
{{- define "install.roleBindingKind" -}}
{{- if .Values.singleNamespace -}}
RoleBinding
{{- else -}}
ClusterRoleBinding
{{- end }}
{{- end }}

{{/*
private huawei cloud registry secret name
*/}}
{{- define "install.huaweiRegistrySecretName" }}
{{- printf "%s-huawei-registry" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
mogdb operator full name
*/}}
{{- define "install.managerName" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
common label
*/}}
{{- define "install.labels" }}
app: {{ .Chart.Name }}
{{- end }}

{{- define "install.imagePullSecrets" -}}
imagePullSecrets:
- name: {{ include "install.huaweiRegistrySecretName" . }}
{{- if .Values.imagePullSecrets }}
{{ toYaml .Values.imagePullSecrets }}
{{- else if .Values.imagePullSecretNames }}
{{- range .Values.imagePullSecretNames }}
- name: {{ . | quote }}
{{- end }}{{/* range */}}
{{- end }}{{/* if */}}
{{- end }}{{/* define */}}