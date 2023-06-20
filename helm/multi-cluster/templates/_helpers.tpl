{{/*
common label
*/}}
{{- define "install.labels" }}
name: {{ .Release.Name }}
mogdb.enmotech.io/cluster: {{ .Release.Name }}
{{- end }}
