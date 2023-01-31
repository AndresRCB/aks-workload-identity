output "ingress_tls_secret_name" {
    value = local.ingress_secret_name
    description = "The kuberntes secret name for the ingress TLS certificate (for use in ingress objects)"
}