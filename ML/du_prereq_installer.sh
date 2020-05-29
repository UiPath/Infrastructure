#!/bin/bash

exec > >(tee -i AIF-log.txt)

#checking  OS
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
ARCH=$( /bin/arch )

# VulkanFS and container-selinux - required for RHEL and AMZN distros
VULKAN_FS_REPO_PKG="ftp://ftp.pbone.net/mirror/ftp.scientificlinux.org/linux/scientific/7.0/x86_64/updates/security/vulkan-filesystem-1.1.73.0-1.el7.noarch.rpm"
VULKAN_FS_PKG="vulkan-filesystem-1.1.73.0-1.el7.noarch.rpm"
CONTAINER_SELINUX_REPO_PKG="http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-1.el7_6.noarch.rpm"
CONTAINERD_IO="https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm"

echo -e "\e[32mUiPath AIFabric Lite"
tput sgr0
usage() {
    cat <<EOF
usage: $0 options
Examples: $0 --env gpu
OPTIONS:
   --env                AIFabric Lite environment: gpu or cpu.
   --cloud              Configure which cloud provider you are using: azure
   --change-mount       Configuring root directory of persistent Docker state.Enter an empty root directory path (ex. /home/user/).
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
                change-mount)
                    CHANGE_ROOT_PATH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                azure)
                    CLOUD="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
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


if [[ -z "$AIF_ENV" ]] && [[ -z "$CHANGE_ROOT_PATH" ]]; then
    usage
    exit 1
fi

base_prereqs() {
    if [[ -x "$(command -v wget)" ]] && [[ -x "$(command -v lspci)" ]]  ; then
        return
    fi

    # pciutils and wget are not installed on some default images ( ex.: AWS marketplace image)
    if [[ "$distribution"  = "ubuntu"* ]]; then
        sudo apt-get update 
        sudo apt-get upgrade -y 
        sudo apt-get install -y pciutils wget 
        

    elif  [[ "$distribution"  = "rhel"* ]] || [[ "$distribution"  = "centos"* ]] || [[ "$distribution"  = "amzn"* ]]; then
        sudo yum update -y  
        sudo yum install -y pciutils wget  

    else
        echo  "Local OS is not supported. Please install latest version of Docker, NVIDIA DRIVERS v430, NVIDIA-Docker and Docker plugin davfs."
        tput sgr0
        exit 1
    fi

}

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
    rmmod nouveau  || true  


    if [[ "$distribution"  = "ubuntu"* ]]; then

            echo -e "\e[32mInstalling NVIDIA DRIVERS"
            sudo add-apt-repository ppa:graphics-drivers/ppa -y   && \
            sudo apt-get -y update 1> /dev/null && \
            sudo apt-get install linux-headers-$(uname -r) 1> /dev/null && \
            sudo apt-get install -y build-essential gcc-multilib dkms 1> /dev/null && \
            if [[ "$distribution"  = "ubuntu16."* ]]; then 
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

            # if nvidia-smi doesn't work, erase nvidia & cuda
            sudo yum erase nvidia cuda

            if [[ "$CLOUD" = "azure" ]]; then
                sudo yum -y update
                sudo yum group install -y "Development Tools"
                sudo yum install -y kernel-devel epel-release dkms
                sudo yum install -y https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
                sudo yum install -y kmod-nvidia.x86_64 nvidia-x11-drv.x86_64 nvidia-detect.x86_64
            else
                sudo yum install -y  https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm  1> /dev/null && \
                sudo yum -y update 1> /dev/null && \
                sudo yum group install -y "Development Tools" 1> /dev/null && \
                sudo yum -y install epel-release && \
                sudo yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) epel-release dkms 1> /dev/null && \
                sudo yum -y install dkms && \
                if [[ "$distribution"  = "rhel8"* ]]; then 
                    sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel8/${ARCH}/cuda-rhel8.repo
                    sudo dnf clean all
                    sudo dnf -y module install nvidia-driver:latest-dkms
                    # sudo dnf -y install cuda -y
                    
                elif [[ "$distribution"  = "rhel7"* ]] || [[ "$distribution"  = "centos7"* ]] || [[ "$distribution"  = "amzn"* ]]; then 
                    sudo yum-config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel7/${ARCH}/cuda-rhel7.repo
                    sudo yum sudo yum clean expire-cache
                    sudo yum install -y nvidia-driver-latest-dkms
                    # sudo yum install cuda -y
                else
                    sudo yum install -y kmod-nvidia.x86_64 nvidia-x11-drv.x86_64 nvidia-detect.x86_64
                fi  && \
                echo -e "\e[32m**************NVIDIA DRIVERS install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DRIVERS install FAILED! --------------"
                tput sgr0
            fi

    else
            echo  "Local OS is not supported. Please install latest version of Docker, NVIDIA DRIVERS v430 and Docker plugin davfs"
            tput sgr0
            exit 1
    fi

}


dockerify_VM() {

    if [[ "$distribution"  = "ubuntu"* ]]; then

        echo -e "\e[32mInstalling DOCKER"
        sudo apt-get install -y apt-transport-https ca-certificates curl  software-properties-common    && \
        curl  -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -    && \
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"    && \
        sudo apt-get update    && \
        sudo apt-get install -y docker-ce    && \
        sudo usermod -a -G docker $USER    && \
        echo -e "\e[32m**************DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------DOCKER install FAILED! --------------"
        tput sgr0
        systemctl enable --now docker.service

    elif [[ "$distribution"  = "rhel"* ]] || [[ "$distribution"  = "centos"* ]] || [[ "$distribution"  = "amzn"* ]]; then

        echo -e "\e[32mInstalling DOCKER"
        # sudo yum install -y ${CONTAINER_SELINUX_REPO_PKG}    && \
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2    && \
        sudo yum install -y selinux-policy && \
        if [[ "$distribution"  = "rhel8"* ]]; then 
            sudo dnf install -y ${CONTAINERD_IO} 
            sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
            sudo dnf install -y container-selinux
            sudo dnf install -y containerd.io
            sudo dnf -y install docker-ce --nobest
        else
            sudo yum install -y ${CONTAINERD_IO} 
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 
            sudo yum install -y containerd.io
            sudo yum install -y container-selinux 
            sudo yum install -y docker-ce
        fi  && \
        sudo usermod -a -G docker $USER    && \
        echo -e "\e[32m**************DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------DOCKER install FAILED! --------------"
        tput sgr0
        systemctl enable --now docker.service
        systemctl restart docker
    else

        echo  "Local OS is not supported. Please install latest version of Docker, NVIDIA DRIVERS v430 and Docker plugin davfs"
        tput sgr0
        exit 1

    fi

}

install_docker_davfs() {
    if `docker plugin ls  2>&1 | grep -q "uipath/davfs" `;then
            echo -e "\e[32m**************Docker plugin davfs already installed. **************"
            tput sgr0
            return
    fi
    echo -e "\e[32mInstalling Docker plugin: davfs"
    sudo docker plugin disable "uipath/davfs"
    sudo docker plugin rm "uipath/davfs"  
    sudo docker plugin install "uipath/davfs" --grant-all-permissions  && \
    echo -e "\e[32m**************Docker plugin install SUCCESS! **************" || echo -e "\e[31m--------------Docker plugin install FAILED! --------------"

}

test_nvidia_docker() {

        echo -e "\e[32mTEST NVIDIA DOCKER"
        if `docker run --gpus all nvidia/cuda:9.0-base nvidia-smi  2>&1 | grep -q "error waiting for container" `;then
            echo -e "\e[32m**************Please reboot the VM. **************"
            tput sgr0
            exit 1
        fi
        echo -e "\e[32m**************TEST NVIDIA DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------TEST NVIDIA DOCKER install FAILED! --------------"
        tput sgr0
        
}



install_nvidia_docker() {
    if  `which nvidia-container-runtime > /dev/null 2>&1`; then
          echo -e "\e[32m**************NVIDIA Container runtime is present. **************"
          tput sgr0
          return
    fi

    if  ! `which nvidia-smi > /dev/null 2>&1`; then
          echo -e "\e[32m**************NVIDIA DRIVERS are not present. Please reboot your machine. **************" 
          tput sgr0
          return
    fi

    if [[ "$distribution"  = "ubuntu"* ]]; then

        echo -e "\e[32mInstalling NVIDIA Container runtime"
        curl  -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | sudo apt-key add -   && \
        curl  -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list     && \
        sudo apt-get update -y     && \
        sudo apt-get install -y nvidia-container-runtime     && \
        echo -e "\e[32m**************NVIDIA Container runtime install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA Container runtime install FAILED! --------------"
        tput sgr0
        sudo systemctl restart docker 
        # Test if Nvidia-Docker works
        test_nvidia_docker
        tput sgr0
        
    elif  [[ "$distribution"  = "rhel"* ]] || [[ "$distribution"  = "centos"* ]] || [[ "$distribution"  = "amzn"* ]]; then
        # Update repo keys for RHEL-based distros
        DIST=$(sed -n 's/releasever=//p' /etc/yum.conf)
        DIST=${DIST:-$(. /etc/os-release; echo $VERSION_ID)}
        sudo rpm -e gpg-pubkey-f796ecb0 
        sudo gpg --homedir /var/lib/yum/repos/$(uname -m)/$DIST/nvidia-container-runtime/gpgdir --delete-key f796ecb0
        # curl  -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
        sudo yum clean expire-cache && \
        sudo yum makecache && \
        sudo yum update -y

        echo -e "\e[32mInstalling NVIDIA Container runtime"
        curl  -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.repo |   sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo
        sudo yum clean expire-cache && \
        sudo yum makecache -y && \
        sudo yum install -y nvidia-container-runtime   && \
        sudo systemctl restart docker && \
        echo -e "\e[32m**************NVIDIA Container runtime install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA Container runtime install FAILED! --------------"
        tput sgr0
        sudo systemctl restart docker
        # Test if Nvidia-Docker works
        test_nvidia_docker
        tput sgr0

    else
        echo  "Local OS is not supported. Please install latest version of Docker, NVIDIA DRIVERS v430, NVIDIA-Docker and Docker plugin davfs."
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

change_mount_docker() {

            read -p "Configuring root directory of persistent Docker state. Please type yes to configure the directory or no to exit: " cm_docker

                case $cm_docker in

                    yes|Yes)  echo "Configuring root directory of persistent Docker state."

                        read -p "Enter an empty root directory path (ex. /home/user/): " cm_docker_path
                        while [[ ! "$cm_docker_path" =~ ^(.+)\/([^/]+)$ ]]; do
                            read -p "$cm_docker_path is not valid root directory path: " cm_docker_path
                        done
                        if [ ! -d "$cm_docker_path" ]; then
                            sudo mkdir -p "$cm_docker_path"
                        fi
                        if [ "$(ls -A $cm_docker_path)" ]; then
                            echo "$cm_docker_path is not Empty."
                            change_mount_docker
                                
                        else
                            tee /etc/docker/daemon.json <<EOF 1> /dev/null 
{
"data-root": "$cm_docker_path"
}
EOF
                        echo -e "\e[32mStarting Docker.."
                        systemctl restart docker  1> /dev/null
                        echo -e "\e[32mPlease reboot..."
                        fi
                        ;;

                    no|No) echo "Exit"
                            exit 0

                        ;;

                    *) echo "You need to type yes or no"

                           change_mount_docker

                        ;; esac

                    
}

Main() {

    if [[ "$AIF_ENV" == "cpu" ]]; then
        base_prereqs
        install_docker
        install_docker_davfs
    elif [[ "$AIF_ENV" == "gpu" ]]; then
        base_prereqs
        checking_nvidia_gpu
        install_nvidia_driver
        install_docker
        install_docker_davfs
        install_nvidia_docker
    elif [[ ! -z "$CHANGE_ROOT_PATH" ]]; then
        while [[ ! "$CHANGE_ROOT_PATH" =~ ^(.+)\/([^/]+)$ ]]; do
            echo "$CHANGE_ROOT_PATH is not valid root directory path."
            echo "Exiting..."
            exit 1
        done
        if [ ! -d "$CHANGE_ROOT_PATH" ]; then
            sudo mkdir -p "$CHANGE_ROOT_PATH"
        fi
        if [ "$(ls -A $CHANGE_ROOT_PATH)" ]; then
            echo "$CHANGE_ROOT_PATH is not Empty."
            echo "Exiting..."
            exit 1
        else
            tee /etc/docker/daemon.json <<EOF 1> /dev/null 
{
"data-root": "$CHANGE_ROOT_PATH"
}
EOF
                        echo -e "\e[32mStarting Docker.."
                        systemctl restart docker  1> /dev/null
                        echo -e "\e[32mPlease reboot..."
                        fi
    else
        usage
        exit 1
    fi

}

Main