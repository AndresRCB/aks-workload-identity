output "ingress_tls_secret_name" {
    value = local.ingress_secret_name
    description = "The kuberntes secret name for the ingress TLS certificate (for use in ingress objects)"
}

output "ingress_ip_address" {
  value = kubernetes_ingress_v1.aks_helloworld.status.0.load_balancer.0.ingress.0.ip
  description = "Public IP address of the Azure Load Balancer created by ingress-nginx-controller"
}