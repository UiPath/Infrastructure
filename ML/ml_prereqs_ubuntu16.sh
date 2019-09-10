#!/bin/bash

# Install CUDA and cudnn
wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.0.176-1_amd64.deb && \
dpkg -i ./cuda-repo-ubuntu1604_9.0.176-1_amd64.deb && \
apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
apt-get update && \
apt-get install -y cuda-9-0 && \
bash -c 'echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list' && \
apt-get update && \
apt-get install -y --no-install-recommends libcudnn7=7.0.5.15-1+cuda9.0 && \
echo -e "\e[32m**************CUDA and CUDNN install SUCCESS! **************" || echo -e "\e[31m-------------- CUDA and CUDNN install FAILED! --------------"
tput sgr0

# DOCKER

# Set up the docker repository
apt-get update && \
apt-get install apt-transport-https ca-certificates curl software-properties-common && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \ # Install Docker CE -> you might need EE.
apt-get update && \
apt-get install -y docker-ce && \
echo -e "\e[32m**************DOCKER install SUCCESS! **************" || echo -e "\e[31m-------------- DOCKER install FAILED! --------------"
tput sgr0

# NVIDIA Docker

# Add the necessary repository
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  apt-key add - && \
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu16.04/amd64/nvidia-docker.list | \
  tee /etc/apt/sources.list.d/nvidia-docker.list && \
apt-get update && \ # install 
apt-get install -y nvidia-docker2 && \
pkill -SIGHUP dockerd && \
echo -e "\e[32m**************NVIDIA Docker install SUCCESS! **************" || echo -e "\e[31m-------------- NVIDIA Docker install FAILED! --------------"
tput sgr0

# change default container runtime


echo -e "\e[32mDocker default runtime change."
tput sgr0
tee /etc/docker/daemon.json <<EOF
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