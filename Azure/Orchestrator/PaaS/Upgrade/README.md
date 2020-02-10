# UiPathOrchestrator
[![HitCount](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator.svg)](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator)

[![Build Status](https://dev.azure.com/hteo-dev/Orchestrator/_apis/build/status/hteo1337.UiPathOrchestrator?branchName=master)](https://dev.azure.com/hteo-dev/Orchestrator/_build/latest?definitionId=4&branchName=master)

---
**WARNING, PLEASE READ BEFORE UPGRADING**
---

This ARM template will upgrade UiPath Orchestrator (WebApp - single/multi). You will need the following details:</br>
* Web App name </br>
* Service plan name </br>
* Version to upgrade </br>
* Passphrase </br>

---
**Any additional settings (like elastic search) specified in the web config will be removed and you should manually add them after the upgrade one by one, NOT REPLACING THE WEB CONFIG**
---

## Backup 
The backup will most likely not be used but nevertheless should be done.
*	Backup NuGet Packages – This should be done if the NuGet packages are stored on the Web App local storage (in the NuGetPackages folder). You can use the web app advanced tools (Kudu) to download the packages.
*	Backup the machine key and encryption key from the web config.
*	Backup the application settings – you can use the advanced edit functionality to copy the settings.

## Upgrade

* If upgrading to 19.10.xx, please connect to advanced tools (Kudu) and run the following command in the bin folder (site/wwwroot/bin):

```cmd
rm UiPath.Web*
```
* Restart the web app

[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FUiPath%2FInfrastructure%2Fmaster%2FAzure%2FOrchestrator%2FPaaS%2FUpgrade%2Forchupgrade.json)
