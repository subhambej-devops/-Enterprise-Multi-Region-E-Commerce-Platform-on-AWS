param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("global", "primary", "secondary")]
  [string]$Environment
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envDir = Join-Path $root "terraform/envs/$Environment"

Push-Location $envDir
try {
  if (Test-Path "backend.hcl") {
    terraform init -backend-config=backend.hcl
  }
  else {
    Write-Warning "backend.hcl not found; initializing with local backend for validation only."
    terraform init -backend=false
  }

  terraform fmt -check -recursive ../../
  terraform validate

  if (Test-Path "terraform.tfvars") {
    terraform plan
  }
  else {
    Write-Warning "terraform.tfvars not found; skipping terraform plan."
  }
}
finally {
  Pop-Location
}
