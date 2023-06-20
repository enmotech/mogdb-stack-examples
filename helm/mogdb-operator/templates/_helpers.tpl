{{/*
mogdb operator full name
*/}}
{{- define "install.managerName" -}}
{{- printf "%s-%s" .Chart.Name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
service account name
*/}}
{{- define "install.serviceAccountName" -}}
{{- printf "%s-%s" .Chart.Name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
role name
*/}}
{{- define "install.roleName" }}
{{- printf "%s-manager-role" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
leader election role name
*/}}
{{- define "install.leaderRoleName" }}
{{- printf "%s-leader-election-role" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
role binding name
*/}}
{{- define "install.roleBindingName" }}
{{- printf "%s-manager-rolebinding" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
leader election role binding name
*/}}
{{- define "install.leaderRoleBindingName" }}
{{- printf "%s-leader-election-rolebinding" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
config map name
*/}}
{{- define "install.configmapName" }}
{{- printf "%s-global-config" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

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
{{- printf "%s-huawei-registry" .Chart.Name | trunc 63 | trimSuffix "-" }}
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

{{/*
common label
*/}}
{{- define "install.labels" }}
control-plane: controller-manager
{{- end }}