# templates/_helpers.tpl

{{- define "aks-command-api.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}
