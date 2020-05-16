Param(
    [string] [Parameter(Mandatory=$true)] $HDclusterLoginUserName,
	[string] [Parameter(Mandatory=$true)] $HDclusterLoginPassword,    
    [string] [Parameter(Mandatory=$true)] $sqlAdminLogin,   
    [string] [Parameter(Mandatory=$true)] $sqlPassword,    
    [string] [Parameter(Mandatory=$true)] $otisTargetRegion,
    [string] [Parameter(Mandatory=$true)] $vmSize, 
    [string] [Parameter(Mandatory=$true)] $environmentName,
    [string] [Parameter(Mandatory=$true)] $environmentType,   
	[string] [Parameter(Mandatory=$false)] $HDTemplateParametersFile = "sa-sql-hdi.mosaic.parameters.json"
	
)

$HDItemplate = Get-ChildItem $HDTemplateParametersFile

#Update CCC template File
foreach($template in $HDItemplate)
{
  $filePath = $template.FullName

  $json = Get-Content -Path $filePath | Out-String | ConvertFrom-Json

  $json.parameters.HDclusterLoginUserName.value = $HDclusterLoginUserName
  $json.parameters.HDclusterLoginPassword.value = $HDclusterLoginPassword
  $json.parameters.sqlAdminLogin.value = $sqlAdminLogin  
  $json.parameters.sqlPassword.value = $sqlPassword
  $json.parameters.otisTargetRegion.value = $otisTargetRegion
  $json.parameters.vmSize.value = $vmSize
  $json.parameters.environmentName.value = $environmentName
  $json.parameters.environmentType.value = $environmentType

   
  $json | ConvertTo-Json -Depth 100 | Out-File -FilePath $filePath -Encoding utf8
}