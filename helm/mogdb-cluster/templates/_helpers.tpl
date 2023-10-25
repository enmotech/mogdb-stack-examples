{{/*
common label
*/}}
{{- define "install.labels" }}
name: {{ .Release.Name }}
mogdb.enmotech.io/cluster: {{ .Release.Name }}
{{- if .Values.labels }}
{{- toYaml .Values.labels }}
{{- end }}
{{- end }}
