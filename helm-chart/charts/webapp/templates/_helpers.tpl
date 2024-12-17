# templates/_helpers.tpl

{{- define "aks-command-app.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}
