{{- define "argocd-apps.destination" -}}
{{- with .destination }}
destination:
  server: {{ .server | default "https://kubernetes.default.svc" }}
  {{- with .namespace }}
  namespace: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
