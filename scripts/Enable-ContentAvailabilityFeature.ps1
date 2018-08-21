[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ -PathType Container -IsValid })]
    [string]$SitecoreAzureToolkitRoot,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ (Test-Path $_ -PathType Leaf) -and ($_ -match '\.scwdp.zip$') })]
    [string]$Path,

    [ValidateScript({ Test-Path $_ -PathType Container -IsValid })]
    [string]$AzureSearchConfig
)
Import-Module "$SitecoreAzureToolkitRoot\tools\Sitecore.Cloud.Cmdlets.dll"
Add-Type -Path "$SitecoreAzureToolkitRoot\tools\DotNetZip.dll"

$scWdpPath = (Resolve-Path $Path).Path

try {
    # Must use DotNetZip to manipulate WDPs. MSDeploy will not recognize files added through PowerShell or .NET zip functions
    $zip = [Ionic.Zip.ZipFile]::new($scWdpPath)

    # Enable Content Availability Config
    $contentAvailabilityConfig = $zip.Entries | Where-Object { $_.FileName.EndsWith("Sitecore.Publishing.Service.ContentAvailability.config.disabled") }
    $contentAvailabilityConfig.FileName = [System.IO.Path]::ChangeExtension($contentAvailabilityConfig.FileName, $null).TrimEnd(".")

    # Enable Solr Content Availability Config
    $solrConfig = $zip.Entries | Where-Object { $_.FileName.EndsWith("Sitecore.Publishing.Service.ContentAvailability.solr.config.disabled") }
    $solrConfig.FileName = [System.IO.Path]::ChangeExtension($solrConfig.FileName, $null).TrimEnd(".")

    # Add Azure Search Content Availability Config
    if ($AzureSearchConfig) {
        $zip.AddFile($AzureSearchConfig, "Content\Website\App_Config\Modules\PublishingService") | Out-Null
    }

    $zip.Save()
} finally {
    if ($zip) { $zip.Dispose() }
    if ($parametersStream) { $parametersStream.Dispose() }
}
