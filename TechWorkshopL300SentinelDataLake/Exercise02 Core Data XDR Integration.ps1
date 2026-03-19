param(
    [string]$subID = "3ee59855-3671-40eb-88cf-68f92f5481a1",
    [string]$resourcegroup = "rg-sentinel-custom-lab",
    [string]$vmname = "vm-sentinel-lab",
    [string]$region = "centralus",
    [string]$workspaceName = "law-sentinel-custom-lab"

)

## --------------------------------------------------------------------------------------------------------
## Task 01: Create Log Analytics Workspace

# Set the subscription context
Write-Host "Setting subscription context..." -ForegroundColor Yellow
az account set --subscription $subID

# Check if resource group exists, create if it doesn't
Write-Host "Checking if resource group '$resourcegroup' exists..." -ForegroundColor Yellow
$rgExists = az group exists --name $resourcegroup --output tsv

if ($rgExists -eq "false") {
    Write-Host "Creating resource group '$resourcegroup' in region '$region'..." -ForegroundColor Yellow
    az group create `
        --name $resourcegroup `
        --location $region
    Write-Host "Resource group created successfully!" -ForegroundColor Green
} else {
    Write-Host "Resource group '$resourcegroup' already exists." -ForegroundColor Green
}

# Check if Log Analytics Workspace already exists
Write-Host "Checking if Log Analytics Workspace '$workspaceName' exists..." -ForegroundColor Yellow
$workspaceExists = az monitor log-analytics workspace show `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --query name `
    --output tsv 2>$null

if ($workspaceExists) {
    Write-Host "Log Analytics Workspace '$workspaceName' already exists." -ForegroundColor Green
    $workspaceId = az monitor log-analytics workspace show `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --query id `
        --output tsv
    Write-Host "Workspace ID: $workspaceId" -ForegroundColor Cyan
} else {
    # Create Log Analytics Workspace
    Write-Host "Creating Log Analytics Workspace '$workspaceName'..." -ForegroundColor Yellow
    az monitor log-analytics workspace create `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --location $region `
        --retention-time 30 `
        --sku PerGB2018 `
        --tags Environment=Production Purpose=Sentinel Service=XDR
    
    Write-Host "Log Analytics Workspace created successfully!" -ForegroundColor Green
    
    # Get workspace details
    $workspaceId = az monitor log-analytics workspace show `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --query id `
        --output tsv
    
    $workspaceCustomerId = az monitor log-analytics workspace show `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --query customerId `
        --output tsv
    
    Write-Host ""
    Write-Host "Workspace Details:" -ForegroundColor Cyan
    Write-Host "  Name: $workspaceName" -ForegroundColor White
    Write-Host "  Resource Group: $resourcegroup" -ForegroundColor White
    Write-Host "  Location: $region" -ForegroundColor White
    Write-Host "  Workspace ID: $workspaceId" -ForegroundColor White
    Write-Host "  Customer ID: $workspaceCustomerId" -ForegroundColor White
}

Write-Host ""
Write-Host "Log Analytics Workspace setup completed successfully!" -ForegroundColor Green

## --------------------------------------------------------------------------------------------------------
## Task 02: Onboard Microsoft Sentinel to the Log Analytics Workspace

Write-Host ""
Write-Host "Onboarding Microsoft Sentinel to Log Analytics workspace..." -ForegroundColor Yellow

# Check if Sentinel is already onboarded
$sentinelExists = az sentinel onboard show `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --query name `
    --output tsv 2>$null

if ($sentinelExists) {
    Write-Host "Microsoft Sentinel is already onboarded to workspace '$workspaceName'." -ForegroundColor Green
} else {
    # Onboard Microsoft Sentinel to the Log Analytics workspace
    az sentinel onboard `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName
    
    Write-Host "Microsoft Sentinel has been successfully onboarded to '$workspaceName'!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Sentinel onboarding completed successfully!" -ForegroundColor Green

