param(
    [string]$subID = "3ee59855-3671-40eb-88cf-68f92f5481a1",
    [string]$resourcegroup = "rg-sentinel-lab",
    [string]$vmname = "vm-sentinel-lab",
    [string]$region = "centralus"
)

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
