# Sitecore Publishing Service for Sitecore XM/XP Single Environment

This template deploys the [Sitecore Publishing Service][1] to a Sitecore XM/XP single environment.

**⚠️WARNING⚠️️:** _**DO NOT**_ link directly to the ARM templates here for your deployment. Clone this repository and copy them to your own servers. I do not guarantee this repository will always exist and I may make breaking changes to the templates.

[Credit to Sitecore for this README template.][2]

## Parameters

The `deploymentId` parameter is filled in by the PowerShell script.

| Parameter                    | Description
-------------------------------|------------------------------------------------
| `templateLink`               | Base URL where templates are hosted (e.g., <https://yoursa.blob.core.windows.net/arm/Publishing%20Service/azuredeploy.json>).
| `templateLinkAccessToken`    | Optional. Query string with access token for Storage Account (e.g., `"?st=...&sig=..."`).
| `psMsDeployPackageUrl`       | The HTTP(s) URL of the Sitecore Publishing Service Web Deployment package.
| `psModuleMsDeployPackageUrl` | The HTTP(s) URL of the Sitecore Publishing Module Web Deployment package.

## Web Deployment Packages (WDPs)

Sitecore does not provide WDPs for the Publishing Service; they must be created from the Publishing Service packages on the [Sitecore Download site][1]. [Read this blog post][3] for the process to create the WDPs for this deployment.

## Deploying as part of Sitecore deployment

In order to configure Sitecore deployment parameters to include the Publishing Service:

* Add the following snippet to the `modules` parameter:

```json
{
  "name": "ps",
  "templateLink": "https://yourdomain.com/arm/Publishing%20Service/Single/azuredeploy.json",
  "parameters": {
    "templateLinkAccessToken" : "Optional access token for the template if stored in Azure storage. Otherwise should be empty string.",
    "psMsDeployPackageUrl" : "<URL of the WDP file Sitecore Publishing Service *-x64.wdp.zip>",
    "psModuleMsDeployPackageUrl" : "<URL of the WDP file Sitecore Publishing Module *.scwdp.zip>"
  }
}
```

> **Note**. The [Bootloader module][4] does need to be run for the `ps` module, but if it's in place for other modules, `ps` should be placed before the Bootloader.

[1]: https://dev.sitecore.net/Downloads/Sitecore_Publishing_Service.aspx
[2]: https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates
[3]: https://www.coreysmith.co/sitecore-publishing-service-deploy-to-azure-with-arm-templates/
[4]: https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates/blob/master/MODULES.md
