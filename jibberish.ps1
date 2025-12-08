$rg = 'rgname3'
$loc = 'centralus'
$stg = 'appstoragea'
$app = 'appFunctionA'
$stgSKU = 'Standard_LRS'
$subid = "650cfdc5-486b-4630-93df-176cb090b2e8"

az group show -n $rg

## ---------------------------------------------------------------------
## All Providers
$providerList = az provider list | ConvertFrom-Json

## Registered Providers
$providerList | Where-Object { $_.registrationState -eq 'Registered' } | Format-Table namespace,registrationState, registrationPolicy -AutoSize

## Providers needing registration
$needsRegistration = $providerList | Where-Object { $_.registrationPolicy -ne 'RegistrationRequired' }
$microsoftProviders = $needsRegistration | Where-Object { $_.namespace -like 'Microsoft.*' } 
$microsoftProviders | Format-Table namespace,registrationState, registrationPolicy -AutoSize

## register providers
#az provider register --namespace Microsoft.Storage 
#az provider register --namespace Microsoft.Web

## ---------------------------------------------------------------------
## List SKUs
$loc = 'centralus'
$storagesku = az storage sku list --query "[?locations[0]=='$loc']" | ConvertFrom-Json
$storagesku | Format-Table name, tier, resourceType, kind, locations -AutoSize
$storagesku[0].capabilities

## ---------------------------------------------------------------------
## List Resources
## az resource list --tag 'CreatedOnDate' --query "[].{Name:name, Id:id, Type:type, Tags:tags}" -o table
$resourceList = az resource list | ConvertFrom-Json
$resourceList | Format-Table name,type, tags -AutoSize

## ---------------------------------------------------------------------
## List VM SKUs
$loc = 'centralus'
$computesku = az vm list-skus --location $loc | ConvertFrom-Json
$vmsku = $computesku | Where-Object { $_.resourceType -eq 'virtualMachines' }
$vmsku[0]
$vmsku[0].capabilities

$cpuFilter = @{"vCPUs"="16"}
#$cpuFilter = @{name="vCPUs"; value="16"}
$selectSku = $vmsku | Where-Object { $_.capabilities -contains $cpuFilter}
#$selectSku = $vmsku | Where-Object { $cpuFilter -contains $_.capabilities}
$selectSku | Format-Table name, tier, family, size, capabilities -AutoSize

#$selectSku = $vmsku | Where-Object { $_.capabilities.name -eq 'vCPUs' -and $_.capabilities.value -ge 16 -and $_.capabilities.name -eq 'MemoryGB' -and $_.capabilities.value -ge 32 }
##$vcpu = $vmsku --query "[?capabilities.name=='vCPUs'] | [?capabilities.value=='16']"
#$vmlist = $vmsku | Where-Object { $_.capabilities.name -eq 'vCPUs' }
#$vmlist = $vmsku | Where-Object { $_.capabilities.name -eq 'vCPUs' -and $_.capabilities.value -eq '16' }
