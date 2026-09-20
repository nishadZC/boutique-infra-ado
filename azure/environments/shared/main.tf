module "resource_group" {
  source   = "../../modules/resource_group"
  name     = "${var.prefix}-rg"
  location = var.location
}

# Non-prod ACR: used by dev, qa, staging
# CI pipeline builds and pushes images here
module "acr" {
  source              = "../../modules/acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  acr_name            = "boutiqueacrshared9p2x4"
  tags = {
    purpose    = "non-prod"
    managed_by = "terraform"
  }
}

# Prod ACR: used exclusively by prod environment
# Only promoted, validated images are copied here via the pipeline
# CI pipelines have NO push access to this registry
module "acr_prod" {
  source              = "../../modules/acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  acr_name            = "boutiqueacrprod9p2x4"
  sku                 = "Premium" # Premium required for geo-replication and private endpoints
  tags = {
    purpose    = "prod"
    managed_by = "terraform"
  }
}

