param([string]$StudentName = "Chandan")

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$stage = Join-Path $projectRoot ("Kubernetes_" + $StudentName)
$zip = "$stage.zip"
$required = @("01-minikube-status.png", "02-images.png", "03-pods-services.png", "04-health.png", "05-browser.png")
$missing = $required | Where-Object { -not (Test-Path (Join-Path $PSScriptRoot "screenshots/$_")) }
if ($missing) { throw "Add required screenshots first: $($missing -join ', ')" }

if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item "$projectRoot/backend" $stage -Recurse
Copy-Item "$projectRoot/frontend" $stage -Recurse
Copy-Item "$PSScriptRoot/k8s" $stage -Recurse
Copy-Item "$PSScriptRoot/screenshots" $stage -Recurse
Copy-Item "$PSScriptRoot/README.md", "$PSScriptRoot/STUDENT_DETAILS.txt", "$PSScriptRoot/Kubernetes_Deployment_Guide.docx" $stage
Get-ChildItem $stage -Recurse -Force -File | Where-Object { $_.Name -eq '.env' } | Remove-Item -Force
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path $stage -DestinationPath $zip
Write-Host "Created $zip"
