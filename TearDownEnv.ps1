## parameters
## subid: Subscription ID to use for cleanup, default is "650cfdc5-486b-4630-93df-176cb090b2e8"
## MCAPS tenant sub = 3ee59855-3671-40eb-88cf-68f92f5481a1
param(
  [string]$subid = "650cfdc5-486b-4630-93df-176cb090b2e8"
)

## Set Subscription
try {
  az account set --subscription $subid
  if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI command failed: $result"
  }
  Write-Host "Subscription set to $subid"
} catch {
  Write-Error "Failed to set subscription!!"
  exit
}

## Get Resource Groups
$rglist = az group list | ConvertFrom-Json

foreach($rg in $rglist) {

  $rgname = $rg.name
  Write-Output "Found Resource Group: $rgname"

  ## List Resources in the Resource Group
  if($rgname -notlike "Default*") {

    $itemlist = az resource list --resource-group $rgname | ConvertFrom-Json
    $rcount = $itemlist.length
    Write-Output "  Number of resources in $rgname = $rcount"

    if($rcount -le 0) {
      Write-Output "  No resources found in this resource group."
    } else {
      Write-Output "  Resources Found in Resource Group: $rgname"
      $itemlist | Format-Table name,type,id -AutoSize
      ## Cleanup
      Write-Warning "  Cleanup: $rgname"
      $input = Read-Host "Enter Y to delete all resources"
      if ($input -eq "Y") {
        foreach($item in $itemlist) {
          $itemname = $item.name
            Write-Warning "  Deleting...: $itemname"
            az resource delete --ids $item.id
          }
      }
    }

    ## Cleanup
    Write-Warning "Cleanup Resource Group: $rgname"
    $input = Read-Host "Enter Y to delete the resource group"
    if ($input -eq "Y") {
      az group delete -n $rgname --yes
      Write-Warning "  Deleting...: $rgname"
    }

  }

}

## List Resource Groups
Write-Output "Found Resource Groups:"
az group list | ConvertFrom-Json | Format-Table name,location -AutoSize


