
#Requires -Version 3.0
#Requires -Module AzureRM.Resources
#Requires -Module Azure.Storage

Param(
    [string] [Parameter(Mandatory=$true)] $SubscriptionId, #The ID of the azure application
    [string] [Parameter(Mandatory=$true)] $ApplicationId, #The ID of the application
    [string] [Parameter(Mandatory=$true)] $ApplicationSecret, #The "secret" key created for the application
    [string] [Parameter(Mandatory=$true)] $AadDirectoryId, #Tenanet ID of AAD
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName, #The place where resources will be listed
    [string] [Parameter(Mandatory=$false)][ValidateScript({Test-Path $_})] $RabbitMQTemplateFile = "rmq.mosaic.template.json",
    [string] [Parameter(Mandatory=$false)][ValidateScript({Test-Path $_})] $RabbitMQTemplateParametersFile = "rmq.mosaic.parameters.json",
    [string] [Parameter(Mandatory=$false)][ValidateScript({Test-Path $_})] $HDTemplateFile = "sa-sql-hdi.mosaic.template.json",
    [string] [Parameter(Mandatory=$false)][ValidateScript({Test-Path $_})] $HDTemplateParametersFile = "sa-sql-hdi.mosaic.parameters.json",
    [string] [Parameter(Mandatory=$false)][ValidateScript({Test-Path $_})] $mysqlwaTemplateFile = "mysql-wa.mosaic.template.json",    
    [string] [Parameter(Mandatory=$false)][ValidateScript({Test-Path $_})] $mysqlwaTemplateParametersFile = "mysql-wa.mosaic.parameters.json"	
)


#No restrictions; all Windows PowerShell scripts can be run
#Set-ExecutionPolicy Unrestricted

$CBMLogFileName = ".\CBM_log-$(get-date -f yyyy-MM-ddTHH-mm-ss).txt"
$RabbitMQErrorFileNameDS = ".\RabbitMQ_errorDS-$(get-date -f yyyy-MM-ddTHH-mm-ss).txt"
$HDIErrorFileNameMS = ".\HDI_errorMS-$(get-date -f yyyy-MM-ddTHH-mm-ss).txt"
$mysqlErrorFileName = ".\Mysql_error-$(get-date -f yyyy-MM-ddTHH-mm-ss).txt"
$PScriptRoot = (Split-Path -parent $MyInvocation.MyCommand.Definition)
[System.Console]::writeLine("File Path : $PScriptRoot")

#Obtain new credentials 
$secpasswd = ConvertTo-SecureString "$ApplicationSecret" -AsPlainText -Force
$subcreds = New-Object System.Management.Automation.PSCredential ("$ApplicationId", $secpasswd)
Login-AzureRmAccount -ServicePrincipal -Tenant $AadDirectoryId -Credential $subcreds -SubscriptionId $SubscriptionId

#Check to see if Resource Group exists
$resourceGroupNameResult = Get-AzureRmResourceGroup -Name "$ResourceGroupName" -ErrorAction SilentlyContinue
if($resourceGroupNameResult -ne $null)
{
    "ResourceGroup exists $ResourceGroupName"
    #RabbitMQ
    Write-Host("Deploying RabbitMQ Cluster.......")
	New-AzureRmResourceGroupDeployment -Name "RabbitMQ-$(get-date -f yyyy-MM-ddTHH-mm-ss)" -ResourceGroupName "$ResourceGroupName" `
								-TemplateFile "$RabbitMQTemplateFile" -TemplateParameterFile "$RabbitMQTemplateParametersFile" `
								-Force -Verbose 2>> $RabbitMQErrorFileNameDS | Out-File $CBMLogFileName -ErrorVariable ErrorMessages    
    $errorsDS=Get-Content $RabbitMQErrorFileNameDS -Raw
    if($errorsDS -ne $null)
    {
    Write-Error $errorsDS
    }

    
    
    #Storage, Azure SQL and HDInsight
    Write-Host("Deploying storage, Azure SQL and HDInsight.........")
	New-AzureRmResourceGroupDeployment -Name "HDI-$(get-date -f yyyy-MM-ddTHH-mm-ss)" -ResourceGroupName "$ResourceGroupName" `
								-TemplateFile "$HDTemplateFile" -TemplateParameterFile "$HDTemplateParametersFile" `
								-Force -Verbose 2>> $HDIErrorFileNameMS | Out-File $CBMLogFileName -ErrorVariable ErrorMessages    
    $errorsMS= Get-Content $HDIErrorFileNameMS -Raw 
    if($errorsMS -ne $null)
    {
    Write-Error $errorsMS
    }
    

    #mysql and WebAPPs
    Write-Host("Deploying mysql and Webapps.........")
	New-AzureRmResourceGroupDeployment -Name "mysql-$(get-date -f yyyy-MM-ddTHH-mm-ss)" -ResourceGroupName "$ResourceGroupName" `
								-TemplateFile "$mysqlwaTemplateFile" -TemplateParameterFile "$mysqlwaTemplateParametersFile" `
								-Force -Verbose 2>> $mysqlErrorFileName | Out-File $CBMLogFileName -ErrorVariable ErrorMessages    
    $errors=Get-Content $mysqlErrorFileName -Raw 
     if($errors -ne $null)
    {
    Write-Error $errors
    }   
    
	}
else
{
    "Resource Group " + $ResourceGroupName + " Not Found"
}