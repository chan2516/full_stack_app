param([string]$StudentName = "Chandan")
$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$stage = Join-Path $projectRoot ("Terraform_AWS_" + $StudentName)
$zip = "$stage.zip"
$pngs = Get-ChildItem (Join-Path $PSScriptRoot "screenshots") -Filter *.png -ErrorAction SilentlyContinue
if ($pngs.Count -lt 13) { throw "Add all 13 required screenshots before packaging." }
if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item "$projectRoot/backend", "$projectRoot/frontend" $stage -Recurse
Copy-Item "$PSScriptRoot/part-1-single-ec2", "$PSScriptRoot/part-2-separate-ec2", "$PSScriptRoot/part-3-ecs", "$PSScriptRoot/screenshots" $stage -Recurse
Copy-Item "$PSScriptRoot/README.md", "$PSScriptRoot/STUDENT_DETAILS.txt", "$PSScriptRoot/Terraform_AWS_Deployment_Guide.docx" $stage
Get-ChildItem $stage -Recurse -Force -File | Where-Object { $_.Name -in @('.env','terraform.tfvars','backend.hcl') -or $_.Name -like '*.tfstate*' } | Remove-Item -Force
Get-ChildItem $stage -Recurse -Force -Directory | Where-Object { $_.Name -eq '.terraform' } | Remove-Item -Recurse -Force
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path $stage -DestinationPath $zip
Write-Host "Created $zip"
