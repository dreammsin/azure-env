param(
    [string]$subID = "3ee59855-3671-40eb-88cf-68f92f5481a1",
    [string]$resourcegroup = "rg-sentinel-lab",
    [string]$vmname = "vm-sentinel-lab",
    [string]$workspaceName = "law-sentinel-xdr-lab"
)

Write-Host "Starting cleanup process..." -ForegroundColor Yellow

# Set the subscription context
az account set --subscription $subID

# Disable Defender for Endpoint integration
Write-Host "Disabling Defender for Endpoint integration..." -ForegroundColor Yellow
az security setting update `
    --name WDATP `
    --status Disabled
#    --enabled false

# Disable auto-provisioning for Log Analytics agent
Write-Host "Disabling auto-provisioning for Log Analytics agent..." -ForegroundColor Yellow
az security auto-provisioning-setting update `
    --name default `
    --auto-provision Off

# Remove workspace settings
Write-Host "Removing workspace settings..." -ForegroundColor Yellow
az security workspace-setting delete --name default #--yes

# Disable Microsoft Defender for Servers (set to Free tier)
Write-Host "Disabling Microsoft Defender for Servers..." -ForegroundColor Yellow
az security pricing create `
    --name VirtualMachines `
    --tier Free

# Delete the VM
Write-Host "Deleting Virtual Machine..." -ForegroundColor Yellow
az vm delete --resource-group $resourcegroup --name $vmname --yes --no-wait

# Delete the Log Analytics workspace
Write-Host "Deleting Log Analytics workspace..." -ForegroundColor Yellow
az monitor log-analytics workspace delete `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --yes `
    --force true

# Delete the entire resource group
Write-Host "Deleting resource group..." -ForegroundColor Yellow
az group delete --name $resourcegroup --yes --no-wait

Write-Host "Cleanup process initiated. Resources are being deleted in the background." -ForegroundColor Green
Write-Host "Note: It may take several minutes for all resources to be fully removed." -ForegroundColor Cyan
