[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ -PathType Container -IsValid })]
    [string]$SitecoreAzureToolkitRoot,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ (Test-Path $_ -PathType Leaf) -and ($_ -match '\.zip$') })]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ -PathType Container -IsValid })]
    [string]$Destination,

    [switch]$GenerateCdPackage
)
Import-Module "$SitecoreAzureToolkitRoot\tools\Sitecore.Cloud.Cmdlets.dll"
Add-Type -Path "$SitecoreAzureToolkitRoot\tools\DotNetZip.dll"

$sourcePath = (Resolve-Path $Path).Path
if(!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination
}
$destinationPath = (Resolve-Path $Destination).Path

$scWdpPath = ConvertTo-SCModuleWebDeployPackage `
    -Path "$sourcePath" `
    -Destination "$destinationPath" `
    -Verbose `
    -Force

try {
    # Add Publishing Service URL parameter into WDP
    $publishingServiceConfig = "Sitecore.Publishing.Service.config"
    [xml]$publishingParameter = `
    "<parameter name=`"Publishing Service URL`" description=`"URL to the Publishing Service Site`" tags=`"Hidden,NoStore`">" +
      "<parameterEntry kind=`"XmlFile`" scope=`"$([Regex]::Escape($publishingServiceConfig))`" match=`"/configuration/sitecore/settings/setting[@name='PublishingService.UrlRoot']/@value`" />" +
    "</parameter>"

    $zip = [Ionic.Zip.ZipFile]::new($scWdpPath)
    $parametersFile = $zip.Entries | Where-Object { $_.FileName -eq "parameters.xml" }
    ($parametersXml = New-Object System.Xml.XmlDocument).Load($parametersFile.OpenReader())
    $parametersXml.parameters.AppendChild($parametersXml.ImportNode($publishingParameter.parameter, $true)) | Out-Null

    $parametersStream = New-Object System.IO.MemoryStream
    $parametersXml.Save($parametersStream)
    $parametersStream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
    $zip.UpdateEntry($parametersFile.FileName, $parametersStream) | Out-Null
    $zip.Save()
} finally {
    if ($zip) { $zip.Dispose() }
    if ($parametersStream) { $parametersStream.Dispose() }
}

if (!$GenerateCdPackage) { return }
Remove-SCDatabaseOperations -Path "$scWdpPath" -Destination "$destinationPath" -Verbose -Force
