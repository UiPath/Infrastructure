# UiPathOrchestrator
[![HitCount](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator.svg)](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator)

[![Build Status](https://dev.azure.com/hteo-dev/Orchestrator/_apis/build/status/hteo1337.UiPathOrchestrator?branchName=master)](https://dev.azure.com/hteo-dev/Orchestrator/_build/latest?definitionId=4&branchName=master)

---
**WARNING, PLEASE READ BEFORE UPGRADING**
---

This ARM template will upgrade UiPath Orchestrator (WebApp - single/multi). The upgrade should be done only to a minor version (eg: from 2018.4.3 to 2018.4.5), doing an upgrade to a major version (eg: from 2019.4.5 to 2019.10.11) might brake the Orchestrator functionality. To upgrade to a minor version you will need the following details:</br>
* Web App name </br>
* Service plan name </br>
* Version to upgrade </br>
* Passphrase (If you do not have a passphrase from the previous deployment you need to copy the rows with Encryption key and Machine Key + validation key and paste them after the upgrade in the web.config. Please stop the webApp before upgrade.) </br>

---
**Any additional settings (like elastic search) specified in the web config will be removed and you should manually add them after the upgrade one by one, NOT REPLACING THE WEB CONFIG**
---

## Backup 
The backup will most likely not be used but nevertheless should be done.
*	Backup NuGet Packages – This should be done if the NuGet packages are stored on the Web App local storage (in the NuGetPackages folder). You can use the web app advanced tools (Kudu) to download the packages.
*	Backup the machine key and encryption key from the web config.
*	Backup the application settings – you can use the advanced edit functionality to copy the settings.

## Upgrade
* Upgrading to a major version please use the method mentioned in here:
https://docs.uipath.com/orchestrator/docs/updating-using-the-azure-script
* Upgrading to a minor version you can use this template


[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FUiPath%2FInfrastructure%2Fmaster%2FAzure%2FOrchestrator%2FPaaS%2FUpgrade%2Forchupgrade.json)
