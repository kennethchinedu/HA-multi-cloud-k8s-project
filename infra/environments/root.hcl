


generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
  
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
  }
}



provider "kubernetes" {
  config_path    = "~/.kube/config"
  
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    
  }
}
EOF
}

#Defining Global tags 
locals {
  environment = basename(path_relative_to_include()) 

  global_tags = {
    Project     = "SRE-PROJECT"
    ManagedBy   = "DevOps_Team"
    Environment = local.environment
  }
}
