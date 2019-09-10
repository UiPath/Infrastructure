# ML-prereqs

yum install pciutils            <br>
lspci -k | grep -A 2 -i "VGA"            <br>
lspci | grep -i NVIDIA            <br>


Azure            <br>
NC6 types ( don't use NV models)            <br>
Red Hat Enterprise Linux Server release 7.7 (Maipo)            <br>
Red Hat Enterprise Linux 7 (.latest, LVM)  < from marketplace >            <br>

AWS            <br>
g2.2xlarge types            <br>
Red Hat Enterprise Linux Server release 7.2 (Maipo)            <br>
RHEL-7.2_HVM_GA-20151112-x86_64-1-Hourly2-GP2 < from marketplace >            <br>            <br>

GCP - default RHEL 7             <br>


Test the installation with :            <br>
1) nvidia-smi             <br>
If doesn't work or you get error like : "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running." , then follow these docs according to the cloud where the VM was deployed. Also please note, you will need to use GCPU familiy type on AWS and Azure, except GCP where you will need to add the GPU manually.            <br>

Output :            <br>
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.87.00    Driver Version: 418.87.00    CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla K80           Off  | 00003130:00:00.0 Off |                    0 |
| N/A   35C    P0    77W / 149W |      0MiB / 11441MiB |      1%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+

2) sudo docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi            <br>
sudo docker run --rm nvidia/cuda nvidia-smi            <br>

Output :            <br>
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.87.00    Driver Version: 418.87.00    CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla K80           Off  | 00003130:00:00.0 Off |                    0 |
| N/A   35C    P0    76W / 149W |      0MiB / 11441MiB |     44%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+



Resources :             <br>
https://docs.nvidia.com/deeplearning/sdk/cudnn-install/index.html#installdriver   < Install NVIDIA Drivers >            <br>

https://docs.microsoft.com/en-us/azure/virtual-machines/linux/n-series-driver-setup < Azure - SETUP GPU drivers >            <br>


https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html < AWS Setup GPU drivers >            <br>