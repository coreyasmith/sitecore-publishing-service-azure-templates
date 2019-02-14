[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ (Test-Path $_ -PathType Leaf) -and ($_ -match '\.zip$') })]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ -PathType Container -IsValid })]
    [string]$Destination,

    [ValidateScript({ Test-Path $_ -PathType Container -IsValid })]
    [string]$WebRoot = "D:\home\site\wwwroot"
)

$sourcePath = (Resolve-Path $Path).Path
if(!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination
}
$destinationPath = (Resolve-Path $Destination).Path

$sourcePackage = Copy-Item -Path $sourcePath -Destination $destinationPath -PassThru
$unzippedPath = [IO.Path]::Combine($destinationPath, $sourcePackage.BaseName)
if (Test-Path $unzippedPath) {
    Remove-Item -Recurse -Force $unzippedPath
}
Expand-Archive -Path $sourcePackage.FullName -Destination $unzippedPath -Force

$appInsightsInstrumentationKey = "ApplicationInsightsInstrumentationKey"
$appSettingsFile = "appsettings.json"
$appSettingsFilePath = "$unzippedPath\$appSettingsFile"
$appSettings = Get-Content -Path $appSettingsFilePath -Raw | ConvertFrom-Json
$appSettings.ApplicationInsights.InstrumentationKey = $appInsightsInstrumentationKey
$appSettings | ConvertTo-Json | Set-Content -Path $appSettingsFilePath

$connectionStringsFile = "config\global\sc.connectionstrings.xml"
[xml]$connectionStrings = `
"<Settings>" +
  "<Sitecore>" +
    "<Publishing>" +
      "<ConnectionStrings>" +
        "<Core>`${Sitecore:Publishing:ConnectionStrings:Core}`</Core>" +
        "<Master>`${Sitecore:Publishing:ConnectionStrings:Master}`</Master>" +
        "<Web>`${Sitecore:Publishing:ConnectionStrings:Web}`</Web>" +
      "</ConnectionStrings>" +
    "</Publishing>" +
  "</Sitecore>" +
"</Settings>"
$connectionStrings.Save("$unzippedPath\$connectionStringsFile")

$manifestFile = [IO.Path]::Combine($destinationPath, "manifest.xml")
[xml]$manifestXml = `
"<sitemanifest>" +
  "<contentPath path=`"$($unzippedPath)`" />" +
  "<runCommand path=`"$($WebRoot)\Sitecore.Framework.Publishing.Host.exe schema upgrade -f`" waitInterval=`"30000`" dontUseCommandExe=`"true`" />" +
"</sitemanifest>"
$manifestXml.Save($manifestFile)

$parametersFile = [IO.Path]::Combine($destinationPath, "parameters.xml")
[xml]$parametersXml = `
"<parameters>" +
  "<parameter tags=`"contentPath`" defaultValue=`"Default Web Site/Content`" description=`"Full site path where you would like to install your application (i.e., Default Web Site/Content)`" name=`"Application Path`">" +
    "<parameterEntry type=`"ProviderPath`" scope=`"contentPath`" match=`"$([Regex]::Escape($unzippedPath))`" />" +
  "</parameter>" +
  "<parameter name=`"Application Insights Instrumentation Key`" description=`"Sitecore Application Insights Instrumentation Key`" tags=`"Hidden,NoStore`">" +
    "<parameterEntry kind=`"TextFile`" scope=`"$([Regex]::Escape($appSettingsFile))`" match=`"$($appInsightsInstrumentationKey)`" />" +
  "</parameter>" +
  "<parameter name=`"Core Admin Connection String`" description=`"Connection string to enter into config`" tags=`"SQL, Hidden,NoStore`">" +
    "<parameterEntry kind=`"XmlFile`" scope=`"$([Regex]::Escape($connectionStringsFile))`" match=`"/Settings/Sitecore/Publishing/ConnectionStrings/Core/text()`" />" +
  "</parameter>" +
  "<parameter name=`"Master Admin Connection String`" description=`"Connection string to enter into config`" tags=`"SQL, Hidden,NoStore`">" +
    "<parameterEntry kind=`"XmlFile`" scope=`"$([Regex]::Escape($connectionStringsFile))`" match=`"/Settings/Sitecore/Publishing/ConnectionStrings/Master/text()`" />" +
  "</parameter>" +
  "<parameter name=`"Web Admin Connection String`" description=`"Connection string to enter into config`" tags=`"SQL, Hidden,NoStore`">" +
    "<parameterEntry kind=`"XmlFile`" scope=`"$([Regex]::Escape($connectionStringsFile))`" match=`"/Settings/Sitecore/Publishing/ConnectionStrings/Web/text()`" />" +
  "</parameter>" +
"</parameters>"
$parametersXml.Save($parametersFile)

$outputFile = [IO.Path]::Combine($destinationPath, "$($sourcePackage.BaseName).wdp.zip")
$msDeploy = [IO.Path]::Combine($env:ProgramFiles, 'IIS', 'Microsoft Web Deploy V3', 'msdeploy.exe')
$packageCommand = "& '$msDeploy' --%" +
    " -verb:sync" +
    " -source:manifest='$manifestFile'" +
    " -dest:package='$outputFile'" +
    " -declareParamFile=$parametersFile" +
    " -replace:match='.*sc\.publishing\.sqlazure\.connections\.xml\.example',replace='sc.publishing.sqlazure.connections.xml'" +
    " -replace:match='$([Regex]::Escape($unzippedPath))',replace='Website'"
Invoke-Expression $packageCommand

Remove-Item $sourcePackage -Force
Remove-Item $manifestFile -Force
Remove-Item $parametersFile -Force
Remove-Item $unzippedPath -Recurse -Force
