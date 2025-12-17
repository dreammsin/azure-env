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

## Get VM SKUs with specific capabilities
$cpu8 = $vmsku | Where-Object { $_.capabilities | Where-Object { $_.name -eq 'vCPUs' -and $_.value -eq "8" } }
$cpu8 | Format-Table -AutoSize

## Get VM SKUs with specific capabilities
$x64 = $vmsku | Where-Object {
  $subset = $_.capabilities 
  ( $subset | Where-Object { $_.name -eq 'CpuArchitectureType' -and $_.value -eq 'x64'}) -and 
  ( $subset | Where-Object { $_.name -eq 'vCPUs' -and $_.value -eq '8' }) 
}
$x64 = $vmsku | Where-Object { $subset = $_.capabilities; ( $subset | Where-Object { $_.name -eq 'CpuArchitectureType' -and $_.value -eq 'x64'}) -and ( $subset | Where-Object { $_.name -eq 'vCPUs' -and $_.value -eq '8' }) } 
$x64 | Format-Table -AutoSize

## Get VM Images and providers and offers and skus
az vm image list-publishers --location $loc | ConvertFrom-Json | Sort-Object name | Format-Table -AutoSize
az vm image list-offers --location $loc --publisher Canonical | ConvertFrom-Json | Format-Table -AutoSize
az vm image list-skus --location $loc --publisher Canonical --offer 0001-com-ubuntu-server-jammy | ConvertFrom-Json | Format-Table -AutoSize

az vm image list-skus --location $loc --publisher oracle --offer oracle-linux
$imagelist = az vm image list-skus --location $loc | ConvertFrom-Json | Format-Table name, publisher, offer -AutoSize