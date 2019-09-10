#!/bin/bash

yum install -y  wget make gcc kernel-devel-$(uname -r) kernel-headers-$(uname -r) kernel-$(uname -r)  1> /dev/null
cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist lbm-nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

echo -e "\e[32mInstalling CUDA v9.0 and cudnn7 for RHEL7.x"
tput sgr0

CUDA_REPO_PKG=cuda-repo-rhel7-10.0.130-1.x86_64.rpm #cuda-repo-rhel7-9.0.176-1.x86_64.rpm
CUDNN_REPO_PKG=nvidia-machine-learning-repo-rhel7-1.0.0-1.x86_64.rpm
EPEL_RELEASE_REPO=epel-release-latest-7.noarch.rpm
VULKAN_FS_REPO_PKG=vulkan-filesystem-1.1.73.0-1.el7.noarch.rpm
CONTAINER_SELINUX_REPO_PKG=container-selinux-2.107-1.el7_6.noarch.rpm

rpm --import http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub 1> /dev/null
yum install -y  https://dl.fedoraproject.org/pub/epel/${EPEL_RELEASE_REPO} 1> /dev/null
#sudo rpm -ivh /tmp/${EPEL_RELEASE_REPO} 1> /dev/null
#rm -f /tmp/${EPEL_RELEASE_REPO} 1> /dev/null 
yum install -y  yum-utils dkms 1> /dev/null && \
echo -e "\e[32m************** RHEL DKMS install SUCCESS! **************" || echo -e "\e[31m-------------- RHEL DKMS install FAILED! --------------"
tput sgr0

wget http://mirror.centos.org/centos/7/os/x86_64/Packages/${VULKAN_FS_REPO_PKG}  -O /tmp/${VULKAN_FS_REPO_PKG} 1> /dev/null
wget https://developer.download.nvidia.com/compute/machine-learning/repos/rhel7/x86_64/${CUDNN_REPO_PKG}  -O /tmp/${CUDNN_REPO_PKG}  1> /dev/null

sudo rpm -ivh /tmp/${VULKAN_FS_REPO_PKG} 1> /dev/null && \
yum install -y vulkan-filesystem  1> /dev/null  && \
echo -e "\e[32m************** VULKAN FS install SUCCESS! **************" || echo -e "\e[31m-------------- VULKAN FS install FAILED! --------------"
tput sgr0


wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/${CUDA_REPO_PKG} -O /tmp/${CUDA_REPO_PKG} 1> /dev/null 
sudo rpm -ivh /tmp/${CUDA_REPO_PKG} 1> /dev/null 
rm -f /tmp/${CUDA_REPO_PKG} 1> /dev/null 
sudo yum install -y cuda-drivers 1> /dev/null   && \
echo -e "\e[32m************** CUDA Drivers install SUCCESS! **************" || echo -e "\e[31m-------------- CUDA Drivers install FAILED! --------------"
tput sgr0


sudo rpm -ivh /tmp/${CUDNN_REPO_PKG} 1> /dev/null
yum install -y cuda-9-0  libcudnn7 libnccl  1> /dev/null  && \
echo -e "\e[32m************** CUDA and CUDNN install SUCCESS! **************" || echo -e "\e[31m-------------- CUDA and CUDNN install FAILED! --------------"
tput sgr0

echo "export PATH=/usr/local/cuda-9.0/bin${PATH:+:${PATH}}" >> /etc/profile.d/cuda90.sh
echo "export LD_LIBRARY_PATH=/usr/local/cuda-9.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" >> /etc/profile.d/cuda90.sh
source /etc/profile.d/cuda90.sh

cd /tmp
echo -e "\e[32mInstalling Docker CE"
tput sgr0
rpm --import https://download.docker.com/linux/centos/gpg 1> /dev/null
yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/${CONTAINER_SELINUX_REPO_PKG}  1> /dev/null
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 1> /dev/null
#sudo rpm -ivh /tmp/${CONTAINER_SELINUX_REPO_PKG} 1> /dev/null
#rm -f /tmp/${CONTAINER_SELINUX_REPO_PKG} 1> /dev/null 
yum clean all 1> /dev/null
yum install -y selinux-policy container-selinux  1> /dev/null
yum -y install docker-ce 1> /dev/null && \
#curl -fsSL https://get.docker.com/ | sh 1> /dev/null && \
systemctl enable docker 1> /dev/null && \
echo -e "\e[32m************** Docker CE install SUCCESS! **************" || echo -e "\e[31m-------------- Docker CE install FAILED! --------------"
tput sgr0

echo -e "\e[32mInstalling NVIDIA Docker"
tput sgr0
curl -s -L https://nvidia.github.io/nvidia-docker/centos7/nvidia-docker.repo |
sudo tee /etc/yum.repos.d/nvidia-docker.repo 1> /dev/null
yum clean all 1> /dev/null
yum install -y nvidia-docker2 1> /dev/null  && \
echo -e "\e[32m************** NVIDIA Docker install SUCCESS! **************" || echo -e "\e[31m-------------- NVIDIA Docker install FAILED! --------------"
tput sgr0

echo -e "\e[32mChange Docker default runtime to nvidia-docker"
tput sgr0
tee /etc/docker/daemon.json <<EOF 1> /dev/null 
{
   "runtimes": {
       "nvidia": {
           "path": "/usr/bin/nvidia-container-runtime",
           "runtimeArgs": []
       }
   },
   "default-runtime": "nvidia"
}
EOF
echo -e "\e[32mStarting Docker.."
systemctl start docker  1> /dev/null
echo -e "\e[32mPlease reboot..."
tput sgr0