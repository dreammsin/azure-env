## Environment values
$uid = Get-Date -Format "MMddHHmmss"
$env = $uid + 'test'

$rg = 'rgname' + $env

## parameters
$loc = 'centralus'
$subid = "650cfdc5-486b-4630-93df-176cb090b2e8"

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

## Create RG
az group create -n $rg -l $loc
## Deploy Test Environment
az deployment group create --resource-group $rg --template-file testenv.bicep