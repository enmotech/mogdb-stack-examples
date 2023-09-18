{{/*
common label
*/}}
{{- define "install.labels" }}
name: {{ .Release.Name }}
mogdb.enmotech.io/cluster: {{ .Release.Name }}
{{- end }}

{{/*
config map name
*/}}
{{- define "install.rcloneConfigmapName" }}
{{- printf "%s-rclone-config" "mogdb-operator" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
service account name
*/}}
{{- define "install.serviceAccountName" -}}
{{- printf "%s-controller-manager" "mogdb-operator" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
secret name
*/}}
{{- define "install.tokenSecretName" }}
{{- printf "%s-token" "mogdb-operator" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "install.huaweiRegistrySecretName" }}
{{- printf "%s-huawei-registry" "mogdb-operator" | trunc 63 | trimSuffix "-" }}
{{- end }}