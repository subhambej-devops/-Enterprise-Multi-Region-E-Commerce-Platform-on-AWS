param(
  [string]$ReleaseName = "enterprise-commerce",
  [string]$Namespace = "ecommerce",
  [Parameter(Mandatory = $true)]
  [string]$ImageRegistry,
  [Parameter(Mandatory = $true)]
  [string]$Domain,
  [string]$ImageTag = "local"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$chart = Join-Path $root "helm/ecommerce"
$setArgs = @(
  "--set", "global.imageRegistry=$ImageRegistry",
  "--set", "global.domain=$Domain",
  "--set-string", "global.imageTag=$ImageTag"
)

helm lint $chart @setArgs
helm template $ReleaseName $chart --namespace $Namespace @setArgs
