resource "helm_release" "time" {
  name       = "flask-chart"
  chart      = "../module/helm/flask-chart"
  version    = "0.1.0"
  namespace = "default"
  values = [
    "${file("../module/helm/values.yaml")}"
  ]

  set {
    name  = "image.repository"
    value = var.repository_url
  }

}
