#!/bin/bash

#checking  OS
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

# VulkanFS and container-selinux - required for RHEL and AMZN distros
VULKAN_FS_REPO_PKG="ftp://ftp.pbone.net/mirror/ftp.scientificlinux.org/linux/scientific/7.0/x86_64/updates/security/vulkan-filesystem-1.1.73.0-1.el7.noarch.rpm"
VULKAN_FS_PKG="vulkan-filesystem-1.1.73.0-1.el7.noarch.rpm"
CONTAINER_SELINUX_REPO_PKG="http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-1.el7_6.noarch.rpm"


echo -e "\e[32mUiPath AIFabric Lite"
tput sgr0
usage() {
    cat <<EOF
usage: $0 options
Examples: $0 --env training
OPTIONS:
   --env                AIFabric Lite environment: training or serving.
   --h                  Show this help
EOF
}


optspec=":h:-:"
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                env)
                    AIF_ENV="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                *)
                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}" >&2
                    fi
                    ;;
            esac;;
        h)
            usage
            exit 2
            ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
                exit 2
            fi
            ;;
    esac
done


if [[ -z "$AIF_ENV" ]]; then
    usage
    exit 1
fi

checking_nvidia_gpu() {

    if lspci | grep -i 'nvidia'; then
        return
    else
        echo -e "\e[31m--------------No NVIDIA GPU was detected. Exiting...--------------"
        tput sgr0
        exit 1
    fi

}

install_nvidia_driver() {

    if  `which nvidia-smi > /dev/null 2>&1`; then
          echo -e "\e[32m**************NVIDIA DRIVERS are present. **************" 
          tput sgr0
          return
    fi
    echo 'blacklist nouveau' >> /etc/modprobe.d/disable-nouveau.conf
    rmmod nouveau || true 1> /dev/null

    if [[ "$distribution"  = "ubuntu"* ]]; then

            echo -e "\e[32mInstalling NVIDIA DRIVERS"
            sudo add-apt-repository ppa:graphics-drivers/ppa -y  && \
            sudo apt-get -y update 1> /dev/null && \
            sudo apt-get install linux-headers-$(uname -r) 1> /dev/null && \
            sudo apt-get install -y build-essential gcc-multilib dkms 1> /dev/null && \
            if [ "$distribution"  = "ubuntu16"* ]; then 
                sudo apt install -y nvidia-430 1> /dev/null
            else 
                sudo apt install -y nvidia-driver-430 1> /dev/null
            fi  && \
            echo -e "\e[32m**************NVIDIA DRIVERS install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DRIVERS install FAILED! --------------"
            tput sgr0

    elif  [[ "$distribution"  = "rhel"* ]] || [[ "$distribution"  = "centos"* ]] || [[ "$distribution"  = "amzn"* ]]; then

            echo -e "\e[32mInstalling NVIDIA DRIVERS"
            sudo wget ${VULKAN_FS_REPO_PKG}  -O /tmp/${VULKAN_FS_PKG} 1> /dev/null && \
            sudo rpm -ivh /tmp/${VULKAN_FS_PKG} 1> /dev/null && \
            sudo yum install -y vulkan-filesystem  1> /dev/null  && \
            echo -e "\e[32m************** VULKAN FS install SUCCESS! **************" || echo -e "\e[31m-------------- VULKAN FS install FAILED! --------------"
            tput sgr0

            sudo yum install -y  https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm  1> /dev/null && \
            sudo yum -y update 1> /dev/null && \
            sudo yum group install -y "Development Tools" 1> /dev/null && \
            sudo yum install -y kernel-devel epel-release dkms 1> /dev/null && \
            sudo yum install -y kmod-nvidia.x86_64 nvidia-x11-drv.x86_64 nvidia-detect.x86_64 1> /dev/null && \
            echo -e "\e[32m**************NVIDIA DRIVERS install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DRIVERS install FAILED! --------------"
            tput sgr0

    else
            echo  "Local OS is not supported. Please install latest version of Docker, NVIDIA DRIVERS v430 and Docker plugin uipath davfs"
            tput sgr0
            exit 1
    fi

}


dockerify_VM() {

    if [[ "$distribution"  = "ubuntu"* ]]; then

        echo -e "\e[32mInstalling DOCKER"
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common   && \
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -   && \
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"   && \
        sudo apt-get update   && \
        sudo apt-get install -y docker-ce   && \
        sudo usermod -a -G docker $USER   && \
        echo -e "\e[32m**************DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------DOCKER install FAILED! --------------"
        tput sgr0
        systemctl restart docker && systemctl enable docker && systemctl daemon-reload 

    elif [[ "$distribution"  = "rhel"* ]] || [[ "$distribution"  = "centos"* ]] || [[ "$distribution"  = "amzn"* ]]; then

        echo -e "\e[32mInstalling DOCKER"
        sudo yum install -y ${CONTAINER_SELINUX_REPO_PKG}   && \
        sudo yum install -y selinux-policy container-selinux   && \
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2   && \
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo   && \
        sudo yum install -y docker-ce docker-ce-cli containerd.io   && \
        sudo usermod -a -G docker $USER   && \
        echo -e "\e[32m**************DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------DOCKER install FAILED! --------------"
        tput sgr0
        systemctl restart docker && systemctl enable docker && systemctl daemon-reload

    else

        echo  "Local OS is not supported. Please install latest version of Docker, NVIDIA DRIVERS v430 and Docker plugin uipath davfs"
        tput sgr0
        exit 1

    fi

}

install_uipath_davfs() {

    echo -e "\e[32mInstalling UiPath Docker plugin: davfs"
    sudo docker plugin disable "uipath/davfs"  > /dev/null 2>&1 && \
    sudo docker plugin rm "uipath/davfs"  > /dev/null 2>&1
    sudo docker plugin install "uipath/davfs" --grant-all-permissions > /dev/null 2>&1 && \
    echo -e "\e[32m**************UiPath Docker plugin install SUCCESS! **************" || echo -e "\e[31m--------------UiPath Docker plugin install FAILED! --------------"

}

test_nvidia_docker() {

        echo -e "\e[32mTEST NVIDIA DOCKER"
        docker run --gpus all nvidia/cuda:9.0-base nvidia-smi   && \
        echo -e "\e[32m**************TEST NVIDIA DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------TEST NVIDIA DOCKER install FAILED! --------------"
        tput sgr0
        
}



install_nvidia_docker() {

    if  `whereis nvidia-container-toolkit > /dev/null 2>&1` || `whereis nvidia-container-runtime > /dev/null 2>&1`; then
          echo -e "\e[32m**************NVIDIA Container runtime is present. **************"
          tput sgr0
          return
    fi

    if [[ "$distribution"  = "ubuntu"* ]]; then

        echo -e "\e[32mInstalling NVIDIA Container runtime"
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -   && \
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list   && \
        sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit   && \
        sudo systemctl restart docker   && \
        echo -e "\e[32m**************NVIDIA Container runtime install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA Container runtime install FAILED! --------------"
        tput sgr0
        # Test if Nvidia-Docker works
        test_nvidia_docker
        tput sgr0
        
    elif  [[ "$distribution"  = "rhel"* ]] || [[ "$distribution"  = "centos"* ]] || [[ "$distribution"  = "amzn"* ]]; then
        
        echo -e "\e[32mInstalling NVIDIA Container runtime"
        curl -s -L https://nvidia.github.io/nvidia-container-runtime/rhel7.5/nvidia-container-runtime.repo | sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo
        sudo yum install -y nvidia-container-runtime
        sudo systemctl restart docker
        echo -e "\e[32m**************NVIDIA Container runtime install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA Container runtime install FAILED! --------------"
        tput sgr0

        # Test if Nvidia-Docker works
        test_nvidia_docker
        tput sgr0

    else
        echo  "Local OS is not supported. Please install latest version of Docker, NVIDIA DRIVERS v430, NVIDIA-Docker and Docker plugin uipath davfs."
        tput sgr0
        exit 1
    fi

}



install_docker() {

    if ! [ -x "$(command -v docker)" ]; then
        echo -e "\e[31m--------------DOCKER is not installed! --------------"
        tput sgr0
        dockerify_VM
    else
        echo -e "\e[32m**************DOCKER is already installed. **************" 
        tput sgr0
    fi

}

Main() {

    if [[ "$AIF_ENV" == "serving" ]]; then
        install_docker
        install_uipath_davfs

    elif [[ "$AIF_ENV" == "training" ]]; then

        checking_nvidia_gpu
        install_nvidia_driver
        install_docker
        install_uipath_davfs
        install_nvidia_docker
        
    else
        usage
        exit 1
    fi

}

Main