param(
    [string]$subID = "3ee59855-3671-40eb-88cf-68f92f5481a1",
    [string]$resourcegroup = "rg-sentinel-lab",
    [string]$vmname = "vm-sentinel-lab",
    [string]$region = "centralus",
    [string]$workspaceName = "law-sentinel-xdr-lab"

)

## --------------------------------------------------------------------------------------------------------
## Exercise00-01 Provision Environment
# Set the subscription context
az account set --subscription $subID

# Register Microsoft Sentinel Platform Services resource provider
Write-Host "Registering Microsoft.SentinelPlatformServices resource provider..." -ForegroundColor Yellow
az provider register --namespace Microsoft.SentinelPlatformServices

# Create resource group if it doesn't exist
az group create --name $resourcegroup --location $region

# Create Windows Server VM
az vm create `
    --resource-group $resourcegroup `
    --name $vmname `
    --location $region `
    --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition-hotpatch:latest `
    --size Standard_D2s_v3 `
    --admin-username azureadmin `
    --admin-password 'Sentinel@lab.VirtualMachine(Windows11-40-505-19).Password' `
    --public-ip-sku Standard `
    --public-ip-address-allocation static `
    --nic-delete-option Delete `
    --os-disk-delete-option Delete
#    --public-ip-address-delete-option Delete `

# Wait for VM to be in running state
Write-Host "Waiting for VM to reach running state..." -ForegroundColor Yellow
do {
    $vmStatus = az vm get-instance-view --resource-group $resourcegroup --name $vmname --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv
    Write-Host "Current VM status: $vmStatus"
    if ($vmStatus -ne "VM running") {
        Start-Sleep -Seconds 10
    }
} while ($vmStatus -ne "VM running")

Write-Host "VM is now running!" -ForegroundColor Green

## --------------------------------------------------------------------------------------------------------
## Exercise00-02 Provision LAW
# Set the subscription context
az account set --subscription $subID

# Create Log Analytics workspace
Write-Host "Creating Log Analytics workspace..." -ForegroundColor Yellow
az monitor log-analytics workspace create `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --location $region

Write-Host "Log Analytics workspace created successfully!" -ForegroundColor Green


## --------------------------------------------------------------------------------------------------------
## Exercise00-03 Defender Enable
# Set the subscription context
az account set --subscription $subID

# Enable Microsoft Defender for Servers Plan 2
Write-Host "Enabling Microsoft Defender for Servers Plan 2..." -ForegroundColor Yellow
az security pricing create `
    --name VirtualMachines `
    --tier Standard

Write-Host "Microsoft Defender for Servers Plan 2 has been enabled successfully!" -ForegroundColor Green

# Get the workspace ID
Write-Host "Getting Log Analytics workspace ID..." -ForegroundColor Yellow
$workspaceId = az monitor log-analytics workspace show `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --query id -o tsv

# Enable auto-provisioning for Log Analytics agent
Write-Host "Enabling auto-provisioning for Log Analytics agent..." -ForegroundColor Yellow
az security auto-provisioning-setting update `
    --name default `
    --auto-provision On

# Configure workspace for auto-provisioning
Write-Host "Configuring Log Analytics workspace for auto-provisioning..." -ForegroundColor Yellow
az security workspace-setting create `
    --name default `
    --target-workspace $workspaceId

# Enable Defender for Endpoint integration
Write-Host "Enabling Defender for Endpoint integration..." -ForegroundColor Yellow
az security setting update `
    --name WDATP `
    --status Enabled
#    --enabled true

Write-Host "All configurations completed successfully!" -ForegroundColor Green

