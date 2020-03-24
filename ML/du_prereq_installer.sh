#!/bin/bash

#checking  OS
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

echo -e "\e[32mUiPath AIFabric Lite"
tput sgr0
usage() {
    cat <<EOF
usage: $0 options
Examples: $0 --env training
OPTIONS:
   --env                AIFabric Lite environment: training or serving.
   --h                   Show this help
EOF
}

verbose()
{
    VERBOSE=1
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
        v)    
            verbose
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

install_docker() {

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

    elif [[ "$distribution"  = "rhel7"* ]] || [[ "$distribution"  = "centos7"* ]]; then

        echo -e "\e[32mInstalling DOCKER"
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2   && \
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo   && \
        sudo yum install -y docker-ce docker-ce-cli containerd.io   && \
        sudo usermod -a -G docker $USER   && \
        echo -e "\e[32m**************DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------DOCKER install FAILED! --------------"
        tput sgr0

    else

        echo  "Local OS is not supported"
        exit 1

    fi

}

test_nvidia_docker() {

        echo -e "\e[32mTEST NVIDIA DOCKER"
        docker run --gpus all nvidia/cuda:9.0-base nvidia-smi   && \
        echo -e "\e[32m**************TEST NVIDIA DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------TEST NVIDIA DOCKER install FAILED! --------------"
        tput sgr0
        
}

if [[ "$AIF_ENV" == "serving" ]]; then
        install_docker

elif [[ "$AIF_ENV" == "training" ]]; then

    if [[ "$distribution"  = "ubuntu"* ]]; then

            echo -e "\e[32mInstalling NVIDIA DRIVERS"
            sudo apt-get -y update   && \
            sudo apt-get install linux-headers-$(uname -r)   && \
            sudo apt-get install -y build-essential gcc-multilib dkms   && \
            sudo apt install -y nvidia-driver-430   && \
            echo -e "\e[32m**************NVIDIA DRIVERS install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DRIVERS install FAILED! --------------"
            tput sgr0
            
            ###### Install docker for training env. ###### 
            install_docker
            ###### Install docker for training env. ######

            echo -e "\e[32mInstalling NVIDIA DOCKER"
            curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -   && \
            curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list   && \
            sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit   && \
            sudo systemctl restart docker   && \
            echo -e "\e[32m**************NVIDIA DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DOCKER install FAILED! --------------"
            tput sgr0

            # Test that Nvidia-Docker works
            test_nvidia_docker
            
    elif  [[ "$distribution"  = "rhel7"* ]] || [[ "$distribution"  = "centos7"* ]]; then

            echo -e "\e[32mInstalling NVIDIA DRIVERS"
            sudo yum -y update
            sudo yum group install -y "Development Tools"
            sudo yum install -y kernel-devel epel-release dkms
            sudo yum install -y https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
            sudo yum install -y kmod-nvidia.x86_64 nvidia-x11-drv.x86_64 nvidia-detect.x86_64
            echo -e "\e[32m**************NVIDIA DRIVERS install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DRIVERS install FAILED! --------------"
            tput sgr0

            ###### Install docker for training env. ###### 
            install_docker
            ###### Install docker for training env. ######
            
            echo -e "\e[32mInstalling NVIDIA DOCKER"
            curl -s -L https://nvidia.github.io/nvidia-container-runtime/rhel7.5/nvidia-container-runtime.repo | sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo
            sudo yum install -y nvidia-container-runtime
            sudo systemctl restart docker
            echo -e "\e[32m**************NVIDIA DOCKER install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DOCKER install FAILED! --------------"
            tput sgr0
    
            # Test that Nvidia-Docker works
            test_nvidia_docker

    else
            echo  "Local OS is not supported"
            exit 1
    fi

else
   usage
   exit 1
fi

