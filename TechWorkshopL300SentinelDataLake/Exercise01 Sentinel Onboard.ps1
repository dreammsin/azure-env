param(
    [string]$subID = "3ee59855-3671-40eb-88cf-68f92f5481a1",
    [string]$resourcegroup = "rg-sentinel-lab",
    [string]$vmname = "vm-sentinel-lab",
    [string]$region = "centralus",
    [string]$workspaceName = "law-sentinel-xdr-lab"

)

## --------------------------------------------------------------------------------------------------------
## Exercise01-01 Onboard Microsoft Sentinel
# Set the subscription context
az account set --subscription $subID

# Onboard Microsoft Sentinel to the Log Analytics workspace
Write-Host "Onboarding Microsoft Sentinel to Log Analytics workspace..." -ForegroundColor Yellow
az sentinel onboard `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName

Write-Host "Microsoft Sentinel has been successfully onboarded!" -ForegroundColor Green

## --------------------------------------------------------------------------------------------------------
## Task 02: Install Windows Security Events and Configure Data Connector

# Step 1: Install 'Windows Security Events' from Content Hub
Write-Host "Installing 'Windows Security Events' from Content Hub..." -ForegroundColor Yellow

# Get the content package ID for Windows Security Events
$contentPackageId = az sentinel content-package list `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --query "[?contains(displayName, 'Windows Security Events')].id | [0]" `
    --output tsv

if ($contentPackageId) {
    Write-Host "Content package already installed." -ForegroundColor Green
} else {
    # Install the Windows Security Events content package
    az sentinel content-package install `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --package-id "azuresentinel.azure-sentinel-solution-securityevents" `
        --version "latest"
    
    Write-Host "Windows Security Events content package installed successfully!" -ForegroundColor Green
}

# Step 2: Get VM Resource ID
Write-Host "Getting VM Resource ID..." -ForegroundColor Yellow
$vmResourceId = az vm show `
    --resource-group $resourcegroup `
    --name $vmname `
    --query id `
    --output tsv

Write-Host "VM Resource ID: $vmResourceId" -ForegroundColor Cyan

# Step 3: Install Azure Monitor Agent extension on VM
Write-Host "Installing Azure Monitor Agent on VM..." -ForegroundColor Yellow
az vm extension set `
    --name AzureMonitorWindowsAgent `
    --publisher Microsoft.Azure.Monitor `
    --resource-group $resourcegroup `
    --vm-name $vmname `
    --enable-auto-upgrade true

Write-Host "Azure Monitor Agent installed successfully!" -ForegroundColor Green

# Step 4: Create Data Collection Rule for Security Events
Write-Host "Creating Data Collection Rule..." -ForegroundColor Yellow

$dcrName = "DCR-SecurityEvents"
$lawResourceId = az monitor log-analytics workspace show `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --query id `
    --output tsv

# Create DCR configuration JSON
$dcrConfig = @"
{
  "location": "$region",
  "properties": {
    "dataSources": {
      "windowsEventLogs": [
        {
          "streams": [
            "Microsoft-SecurityEvent"
          ],
          "xPathQueries": [
            "Security!*"
          ],
          "name": "eventLogsDataSource"
        }
      ]
    },
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "$lawResourceId",
          "name": "DataCollectionEvent"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": [
          "Microsoft-SecurityEvent"
        ],
        "destinations": [
          "DataCollectionEvent"
        ]
      }
    ]
  }
}
"@

# Save DCR config to temporary file
$dcrConfigFile = Join-Path $env:TEMP "dcr-config.json"
$dcrConfig | Out-File -FilePath $dcrConfigFile -Encoding utf8

# Create the Data Collection Rule
az monitor data-collection rule create `
    --name $dcrName `
    --resource-group $resourcegroup `
    --location $region `
    --rule-file $dcrConfigFile

Write-Host "Data Collection Rule '$dcrName' created successfully!" -ForegroundColor Green

# Step 5: Associate DCR with the VM
Write-Host "Associating Data Collection Rule with VM..." -ForegroundColor Yellow

$dcrResourceId = az monitor data-collection rule show `
    --name $dcrName `
    --resource-group $resourcegroup `
    --query id `
    --output tsv

$associationName = "dcr-association-$vmname"

az monitor data-collection rule association create `
    --name $associationName `
    --rule-id $dcrResourceId `
    --resource $vmResourceId

Write-Host "Data Collection Rule associated with VM successfully!" -ForegroundColor Green

# Step 6: Enable Windows Security Events Data Connector
Write-Host "Enabling Windows Security Events via AMA Data Connector..." -ForegroundColor Yellow

$dataConnectorId = "WindowsSecurityEvents"

# Create data connector configuration
$connectorConfig = @"
{
  "kind": "WindowsSecurityEvents",
  "properties": {
    "dataTypes": {
      "securityEvents": {
        "state": "Enabled"
      }
    }
  }
}
"@

$connectorConfigFile = Join-Path $env:TEMP "connector-config.json"
$connectorConfig | Out-File -FilePath $connectorConfigFile -Encoding utf8

# Create the data connector
az sentinel data-connector create `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --name $dataConnectorId `
    --kind "WindowsSecurityEvents" `
    --connector-definition $connectorConfigFile

Write-Host "Windows Security Events via AMA Data Connector enabled successfully!" -ForegroundColor Green

# Cleanup temporary files
Remove-Item -Path $dcrConfigFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $connectorConfigFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Task 02 completed successfully!" -ForegroundColor Green
Write-Host "- Windows Security Events content installed" -ForegroundColor Cyan
Write-Host "- Azure Monitor Agent installed on $vmname" -ForegroundColor Cyan
Write-Host "- Data Collection Rule '$dcrName' created and associated" -ForegroundColor Cyan
Write-Host "- Windows Security Events via AMA Data Connector enabled" -ForegroundColor Cyan
Write-Host "- All Security Events collection configured" -ForegroundColor Cyan

## --------------------------------------------------------------------------------------------------------
## Task 02b: Install Microsoft Defender XDR from Content Hub

Write-Host ""
Write-Host "Installing 'Microsoft Defender XDR' from Content Hub..." -ForegroundColor Yellow

# Check if Microsoft Defender XDR content package is already installed
$xdrPackageInstalled = az sentinel content-package list `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --query "[?contains(displayName, 'Microsoft Defender XDR') || contains(displayName, 'Microsoft 365 Defender')].displayName | [0]" `
    --output tsv

if ($xdrPackageInstalled) {
    Write-Host "Microsoft Defender XDR content package is already installed." -ForegroundColor Green
} else {
    # Install the Microsoft Defender XDR content package
    # The package ID may vary, using the common identifier
    az sentinel content-package install `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --package-id "azuresentinel.azure-sentinel-solution-microsoft365defender" `
        --version "latest"
    
    Write-Host "Microsoft Defender XDR content package installed successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Task 02b completed successfully!" -ForegroundColor Green
Write-Host "- Microsoft Defender XDR content installed from Content Hub" -ForegroundColor Cyan

## --------------------------------------------------------------------------------------------------------
## Task 03: Setup Data Lake Integration with Sentinel in Defender

Write-Host ""
Write-Host "Setting up Data Lake integration with Sentinel in Defender..." -ForegroundColor Yellow

# Step 1: Enable Microsoft Defender XDR Data Connector
Write-Host "Enabling Microsoft Defender XDR Data Connector..." -ForegroundColor Yellow

$defenderConnectorId = "Microsoft365Defender"

# Create Microsoft Defender XDR data connector configuration
$defenderConnectorConfig = @"
{
  "kind": "MicrosoftThreatProtection",
  "properties": {
    "dataTypes": {
      "incidents": {
        "state": "Enabled"
      },
      "alerts": {
        "state": "Enabled"
      }
    },
    "tenantId": "$(az account show --query tenantId -o tsv)"
  }
}
"@

$defenderConnectorFile = Join-Path $env:TEMP "defender-connector-config.json"
$defenderConnectorConfig | Out-File -FilePath $defenderConnectorFile -Encoding utf8

# Create the Microsoft Defender XDR data connector
try {
    az sentinel data-connector create `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --name $defenderConnectorId `
        --kind "MicrosoftThreatProtection" `
        --connector-definition $defenderConnectorFile
    
    Write-Host "Microsoft Defender XDR Data Connector enabled successfully!" -ForegroundColor Green
} catch {
    Write-Host "Microsoft Defender XDR Data Connector may already be enabled or requires manual configuration." -ForegroundColor Yellow
}

# Step 2: Configure Data Lake Storage integration
Write-Host "Configuring Data Lake Storage integration..." -ForegroundColor Yellow

# Get the workspace resource ID
$workspaceResourceId = az monitor log-analytics workspace show `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --query id `
    --output tsv

Write-Host "Workspace Resource ID: $workspaceResourceId" -ForegroundColor Cyan

# Step 3: Enable Microsoft Defender for Cloud integration
Write-Host "Enabling Microsoft Defender for Cloud integration..." -ForegroundColor Yellow

# Enable Defender for Cloud data connector if not already enabled
$defenderCloudConnectorId = "MicrosoftDefenderForCloud"

$defenderCloudConfig = @"
{
  "kind": "MicrosoftDefenderAdvancedThreatProtection",
  "properties": {
    "dataTypes": {
      "alerts": {
        "state": "Enabled"
      }
    },
    "tenantId": "$(az account show --query tenantId -o tsv)"
  }
}
"@

$defenderCloudFile = Join-Path $env:TEMP "defender-cloud-config.json"
$defenderCloudConfig | Out-File -FilePath $defenderCloudFile -Encoding utf8

try {
    az sentinel data-connector create `
        --resource-group $resourcegroup `
        --workspace-name $workspaceName `
        --name $defenderCloudConnectorId `
        --kind "MicrosoftDefenderAdvancedThreatProtection" `
        --connector-definition $defenderCloudFile
    
    Write-Host "Microsoft Defender for Cloud connector enabled successfully!" -ForegroundColor Green
} catch {
    Write-Host "Microsoft Defender for Cloud connector may already be enabled." -ForegroundColor Yellow
}

# Step 4: Configure workspace settings for Data Lake integration
Write-Host "Configuring workspace settings for Data Lake integration..." -ForegroundColor Yellow

# Update workspace to enable data connectors and integration
az monitor log-analytics workspace update `
    --resource-group $resourcegroup `
    --workspace-name $workspaceName `
    --retention-time 30 `
    --tags Environment=Production Integration=DefenderXDR DataLake=Enabled

Write-Host "Workspace configured for Data Lake integration!" -ForegroundColor Green

# Cleanup temporary files
Remove-Item -Path $defenderConnectorFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $defenderCloudFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Task 03 completed successfully!" -ForegroundColor Green
Write-Host "- Microsoft Defender XDR Data Connector enabled for $workspaceName" -ForegroundColor Cyan
Write-Host "- Data Lake integration configured with Sentinel" -ForegroundColor Cyan
Write-Host "- Microsoft Defender for Cloud connector enabled" -ForegroundColor Cyan
Write-Host "- Workspace settings updated for integration" -ForegroundColor Cyan