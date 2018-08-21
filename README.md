# Sitecore Publishing Service Azure Templates

This repository contains Azure Resource Manager templates to install the [Sitecore Publishing Service][1] in your Sitecore Azure PaaS environment and scripts to create the necessary Web Deployment Packages.

## ⚠️Warning⚠️

_**DO NOT**_ link directly to the ARM templates in this repository for your deployment. Copy these templates to your own servers. I do not guarantee this repository will always exist and I may make breaking changes to the templates at any point in the future.

## Documentation

The templates here are meant to integrate with the [Sitecore Azure Quickstart Templates][2].

Sitecore does not publish Web Deployment Packages (WDPs) for the Publishing Service, you must create your own. For details on how to create WDPs for the Publishing Service and more information about these templates, read my blog post: <https://www.coreysmith.co/sitecore-publishing-service-deploy-to-azure-with-arm-templates/>.

## Compatibility

These ARM templates have been designed to work with Publishing Service 3.0 in an Azure PaaS environment.

[1]: https://dev.sitecore.net/Downloads/Sitecore_Publishing_Service.aspx
[2]: https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates
