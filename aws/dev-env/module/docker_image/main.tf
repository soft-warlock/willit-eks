resource "null_resource" "build" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = "../module/docker_image"
    command = <<-EOT
    docker build -t ${var.ACCOUNT}.dkr.ecr.${var.REGION}.amazonaws.com/${var.REPO} .
    aws ecr get-login-password \
        --region ${var.REGION} \
    | docker login \
        --username AWS \
        --password-stdin ${var.ACCOUNT}.dkr.ecr.${var.REGION}.amazonaws.com

    docker push ${var.ACCOUNT}.dkr.ecr.${var.REGION}.amazonaws.com/${var.REPO}

    EOT
  }
}
