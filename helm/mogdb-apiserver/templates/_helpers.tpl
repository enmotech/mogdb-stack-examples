{{/*
common labels
*/}}
{{- define "install.labels" }}
vendor: enmotech
{{- end }}

{{- define "install.deployLables" }}
name: {{ .Chart.Name }}
{{- end }}

{{/*
Create the name of the role to use
*/}}
{{- define "install.roleName" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Create the name of the role binding to user
*/}}
{{- define "install.roleBindingName" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Create the name of the service to use
*/}}
{{- define "install.serviceName" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
service labels
*/}}
{{- define "install.serviceLabels" }}
name: {{ .Chart.Name }}
{{- end }}

{{/*
service selector
*/}}
{{- define "install.serviceSelectors" }}
name: {{ .Chart.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "install.serviceAccountName" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Create the name of the mgo user secret to use
*/}}
{{- define "install.userSecretName" -}}
mgouser-admin
{{- end }}

{{/*
mgo user labels
*/}}
{{- define "install.userSecretLabels" }}
mgo-created-by: upgrade
mgo-mgouser: "true"
username: admin
{{- end }}

{{/*
Create the name of the mgo role secret to use
*/}}
{{- define "install.roleSecretName" -}}
mgorole-admin
{{- end }}

{{/*
mgo role labels
*/}}
{{- define "install.roleSecretLabels" }}
mgo-created-by: upgrade
mgo-mgorole: "true"
rolename: admin
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
private huawei cloud registry secret name
*/}}
{{- define "install.huaweiRegistrySecretName" }}
{{- printf "%s-huawei-registry" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "install.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{ toYaml .Values.imagePullSecrets }}
{{- else if .Values.imagePullSecretNames }}
imagePullSecrets:
{{- range .Values.imagePullSecretNames }}
- name: {{ . | quote }}
{{- end }}{{/* range */}}
{{- end }}{{/* if */}}
{{- end }}{{/* define */}}

{{/*
mogdb apiserver full name
*/}}
{{- define "install.managerName" -}}
{{- printf "%s-%s" .Chart.Name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}