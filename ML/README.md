# ML-prereqs
## Installation steps
Run :

```curl -fsSL https://raw.githubusercontent.com/UiPath/Infrastructure/master/ML/prereq_installer.sh | sudo sh ```

## Distros supported on cloud
**Ubuntu 16.04.** <br>
**RHEL 7.x** (except Azure, [click here](#azure------------))**.**<br>

### Azure            <br>
**VM Tier** : NC6.<br> 
Use NV tiers only if you have installed the NVIDIA driver before executing the script or you can use an custom extension script from Azure to install the necessary NVIDIA driver according to that tier GPU model and [also check](#cloud-docs--------------).            <br>
**Image used** : Red Hat Enterprise Linux 7 (.latest, from marketplace).            <br>

### AWS            <br>
**VM Tier** : g2.2xlarge (but also any GPU available tier type).           <br>
**Image used** : Red Hat Enterprise Linux Server release 7.2.            <br>
         <br>            <br>

### GCP
**VM Tier** : any which supports adding a GPU from supported family, [check here](https://docs.uipath.com/activities/docs/deploying-a-local-machine-learning-model).<br>
**Image used** : available RHEL 7 from marketplace.             <br>


## Test the installation            <br>
1) ``` nvidia-smi```             <br>
If doesn't work or you get an error like : "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running." , then follow these docs according to the cloud where the VM was deployed [click here](#cloud-docs--------------).<br>
Also please note, you will need to use GCPU tier type on AWS and Azure, except GCP where you will need to add the GPU manually.            <br>

**Output** :            <br>
![NVIDIA SMI output](https://github.com/UiPath/Infrastructure/blob/master/ML/nvidia-smi.png)

2) ``` sudo docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi```                <br>
``` sudo docker run --rm nvidia/cuda nvidia-smi```       <br>

**Output** :            <br>
![NVIDIA SMI output](https://github.com/UiPath/Infrastructure/blob/master/ML/nvidia-smi.png)



### Cloud docs :             <br>
[Install NVIDIA Drivers](https://docs.nvidia.com/deeplearning/sdk/cudnn-install/index.html#installdriver)    <br>

[Azure - SETUP GPU drivers](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/n-series-driver-setup)      <br>


[AWS Setup GPU drivers](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html)       <br>


#### Before asking for support :
```cat /etc/*[_-]release``` <br>
Install pciutils (**only if it's not installed**) and run:            <br>
```lspci -k | grep -A 2 -i "VGA"```            <br>
```lspci | grep -i NVIDIA```            <br>
**Check the OS version ([click here](#distros-supported-on-cloud)) and supported GPU family** ([check here](https://docs.uipath.com/activities/docs/deploying-a-local-machine-learning-model))