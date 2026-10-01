param([string]$StudentName = "Chandan")

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$stage = Join-Path $projectRoot ("Kubernetes_" + $StudentName)
$zip = "$stage.zip"
$pngs = Get-ChildItem (Join-Path $PSScriptRoot "screenshots") -Filter *.png -ErrorAction SilentlyContinue
if ($pngs.Count -lt 5) { throw "Add all 5 required screenshots before packaging." }

if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item "$projectRoot/backend" $stage -Recurse
Copy-Item "$projectRoot/frontend" $stage -Recurse
Copy-Item "$PSScriptRoot/k8s" $stage -Recurse
Copy-Item "$PSScriptRoot/screenshots" $stage -Recurse
Copy-Item "$PSScriptRoot/README.md", "$PSScriptRoot/STUDENT_DETAILS.txt", "$PSScriptRoot/Kubernetes_Deployment_Guide.docx" $stage
Get-ChildItem $stage -Recurse -Force -File | Where-Object { $_.Name -eq '.env' } | Remove-Item -Force
Get-ChildItem -Path $stage -Recurse -Directory -Filter "node_modules" | Remove-Item -Recurse -Force
Get-ChildItem -Path $stage -Recurse -Directory -Filter "venv" | Remove-Item -Recurse -Force
Get-ChildItem -Path $stage -Recurse -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path $stage -DestinationPath $zip
Write-Host "Created $zip"
