# UiPathOrchestrator Upgrade - Azure WebApp
[![HitCount](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator.svg)](http://hits.dwyl.io/hteo1337/hteo1337/UiPathOrchestrator)

This ARM template will upgrade UiPath Orchestrator from Azure Marketplace and the one-click deployment from Github.</br></br>

!! Attention !!</br>
Backup the web.config from the WebApp.</br>
Backup the NuGet packages folder if resides in the WebApp. </br>
If you upgrade from 18.x to 19.x you will need to convert all NuGet packages using PackageMigrator or change NuGet.Repository.Type to Legacy, example : ```<add key="NuGet.Repository.Type" value="Legacy" />``` </br>
!! Attention !!</br></br>

Upgrade process :</br>
1. Select the Subscription and the Resource group where the WebApp was deployed.</br>
2. Click the button "Deploy to Azure" and the template will be loaded automatically in the Azure Portal.</br>
3. Complete the following fields:</br>
    -appName - full name of the WebApp resource where the Orchestrator was deployed</br>
    -servicePlanName - full name of the Service Plan resource where the WebApp resides</br>
    -orchestratorVersion - desired upgrade version of the Orchestrator</br>
    -location - location of the WebApp (leave default if it's same location as the Resource group location)</br>
    -passphrase - Passphrase used to generate Application encryption key, NuGet API keys, Machine Decryption and Validation keys (mandatory, in order to re-add them in the new web.config)</br>
    -applicationEncryptionKey - Optional if the application was installed via Azure Marketplace. If the application was installed from PublishOrchestrator powershell script, then you must add the existing Application Encryption key from the web.config</br>
4. Check the box "I agree to the terms and conditions stated above"</br>
5. Click on Purchase and wait until the deployment is finished, then access the URL of the WebApp.</br>


[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FUiPath%2FInfrastructure%2Fmaster%2FAzure%2FOrchestrator%2FPaaS%2FUpgrade%2Fazuredeploy.json)