output ecr_name {
  value = aws_ecr_repository.ecr-repo.name
}

output repository_url {
  value = aws_ecr_repository.ecr-repo.repository_url
}

output ACCOUNT {
  value = aws_ecr_repository.ecr-repo.registry_id
}
