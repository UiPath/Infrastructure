# UiPathOrchestrator
[![HitCount](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator.svg)](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator)

[![Build Status](https://dev.azure.com/hteo-dev/Orchestrator/_apis/build/status/hteo1337.UiPathOrchestrator?branchName=master)](https://dev.azure.com/hteo-dev/Orchestrator/_build/latest?definitionId=4&branchName=master)

This ARM template will deploy UiPath Orchestrator (WebApp - single/multi node with scale out/in settings, depending on the no. of instances) with following resources:
-App Service with UiPath Orchestrator 
-App Service plan
-Azure SQL Server with DB
-Application Insights
-Storage account
-RedisCache (only if the parameter orchestratorInstances is greater than 1 and lower than 10)
-Application Insights Rules (if the selected parameter orchestratorAlertRules is "yes" )


[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FUiPath%2FInfrastructure%2Fmaster%2FAzure%2FOrchestrator%2FPaaS%2FMultiNode%2Fazuredeploy.json)
