aws_region   = "us-east-1"
project_name = "java-reghub"
environment  = "dev"

vpc_id = "vpc-04cc61ff957de7ac1"

subnet_ids = [
  "subnet-0e2276e1fa86a07c1",
  "subnet-0e6fca2ee09e41481",
  "subnet-00fecc48256c5fb0d"
]

instance_type  = "t2.micro"
instance_count = 3

allowed_ssh_cidr_blocks = [
  "174.129.65.182/32"
]

public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCUSm4rF1nO6/pIwklG0QU8rhQ/7NoHgSBOcINqX4RZdczlvdswSmwmlJgKots0VKIfJOQwdn8Wkj0YAMUA0Dk/mgpAayqy9n5csExgzc5uAMtlOvQxjxHdDf0yYKqnnnYXuAn/EXaQDCIWM9spSNPHTTco+yrMu6ZNdlbQ+jBBOsRij45NZbekaDPzG+icBHlp5BK/P8wIIXQb1AVgxWiiS5IZtoPZoD4Yfq9qA7kp1CxYWsPSLHTIO7IiAS3VTpp4NqMoP9NnqNmZU7xFR+bT+ltGVqAnTeptfmvpEVLUNJ264urHf5UVRP5MthQuTXMmPy+YcuhxEfc6sVLZrH9jxWo+AdHtPfkBC1hhvKYS4DGsAgaQDl0YLYv8OkJHFnTpJ8zZ3DMoaTPCiDstqiL3HpM9fYD64brS+y4t3nKBnfnHeHQmkapoKJBrHz4CO2lC6PS+XDUMhhobkXy1+1sc11+wu3/bEvxpnzumP+JVNDF+VQ2a9+DkK4KnO3gcPaVOPND1Qnez7qtS6RvbldVJ6eN0O5AfMiVTvdKGPna2QBhq0tMlQegOU5LtjCt59UCT+SykQ2WwiLDRrFJO3tTbBxYiEPefoWSGxVndYsDUerIYF0IksD/o3ajElGw54kSuC8pTWlnjPA6q38Mskigd2KpaFL0We+YF2SGYUL2iwQ== ubuntu@ip-172-31-33-248"

root_volume_size       = 8
additional_volume_size = 10

common_tags = {
  Owner     = "Vishwas"
  ManagedBy = "Terraform"
  Project   = "Java-reghub"
}