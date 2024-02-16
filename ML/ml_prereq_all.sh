#!/bin/bash

exec > >(tee -i AIF-log.txt)

#checking  OS
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
ARCH=$(/bin/arch)

#setting NEEDRESTART_MODE=a for Ubuntu needrestart, to suppres auto restart services prompt on apt-get upgrade - https://askubuntu.com/questions/1367139/apt-get-upgrade-auto-restart-services
if [[ "$distribution"  = "ubuntu"* ]]; then
    export NEEDRESTART_MODE=a
fi

#Update this variable with the current NVIDIA driver branch
NVIDIA_DRIVER_BRANCH='535'

echo -e "\e[32mUiPath CV Prerequisites"
tput sgr0
usage() {
    cat <<EOF
usage: $0 options
Examples: $0 --env gpu
OPTIONS:
   --env                UiPath CV environment: gpu or cpu.
   --cloud              Configure which cloud provider you are using: azure   
   --h                  Show this help
EOF
}


optspec=":h:-:"
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                env)
                    CV_ENV="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                cloud)
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

check_secure_boot(){

    #If Secure Boot is enabled, prompt the user to disable it and restart the installation

    echo -e "\e[32mChecking status of Secure Boot"
    if mokutil --sb-state | grep enabled;then
        echo -e "\e[31m--------------Secure Boot enabled. Please disable Secure Boot and run the script again. Exiting--------------"
        tput sgr0
        exit 1
    fi
}

base_prereqs() {
    if [[ -x "$(command -v wget)" ]] && [[ -x "$(command -v lspci)" ]] && [[ -x "$(command -v mokutil)" ]] ; then
        return
    fi

    # pciutils and wget are not installed on some default images ( ex.: AWS marketplace image)


    if [[ "$distribution"  = "ubuntu"* ]]; then

         apt-get update 
         apt-get upgrade -y 
         apt-get install -y pciutils wget mokutil
        

    elif  [[ "$distribution"  = "rhel"* ]] || [[ "$distribution"  = "centos"* ]]; then
         yum update -y  
         yum install -y pciutils wget mokutil 

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
    echo -e "\e[32mInstalling NVIDIA DRIVERS. Please be patient"
    if [[ "$distribution"  = "ubuntu"* ]]; then
    
        # Installing current supported LTS Nvidia Driver Brach
        apt-get -y update 1> /dev/null && \
        apt-get install -y nvidia-driver-${NVIDIA_DRIVER_BRANCH}-server 1> /dev/null && \
        echo -e "\e[32mFinished installing server drivers. Installing NVIDIA utils"
        apt-get install -y nvidia-utils-${NVIDIA_DRIVER_BRANCH}-server 1> /dev/null && \
        echo -e "\e[32m**************NVIDIA DRIVERS install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DRIVERS install FAILED! --------------"
        tput sgr0

    elif  [[ "$distribution"  = "rhel8"* ]] || [[ "$distribution"  = "centos"* ]]; then
        dnf config-manager --add-repo=https://developer.download.nvidia.com/compute/cuda/repos/rhel8/${ARCH}/cuda-rhel8.repo
        dnf module install -y nvidia-driver:${NVIDIA_DRIVER_BRANCH} 1> /dev/null && \
        echo -e "\e[32m**************NVIDIA DRIVERS install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA DRIVERS install FAILED! --------------"
        tput sgr0

    else
            echo  "Local OS is not supported. Please install latest version of Podman, NVIDIA DRIVERS v${NVIDIA_DRIVER_BRANCH} and NVIDIA Container Toolkit"
            tput sgr0
            exit 1
    fi

}

install_podman(){
    if ! [ -x "$(command -v podman)" ]; then
        echo -e "\e[31m--------------PODMAN is not installed! --------------"
        tput sgr0        
        echo -e "\e[32mInstalling PODMAN"
        if [[ "$distribution"  = "ubuntu"* ]]; then
        #The official repositories contain version podman 3.4.4 which doesn't work with the nvidia container toolkit. 
        #Installing the latest version available for Ubuntu as per the instructions at https://podman.io/docs/installation#ubuntu
            mkdir -p /etc/apt/keyrings
            curl -fsSL "https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/Release.key" \
            | gpg --dearmor \
            | tee /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg > /dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg]\
            https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/ /" \
            | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null
            apt-get update -qq 1> /dev/null
            apt-get -qq -y install podman 1> /dev/null && \
            echo -e "\e[32m**************PODMAN install SUCCESS! **************" || echo -e "\e[31m--------------PODMAN install FAILED! --------------"
            tput sgr0
        elif [[ "$distribution"  = "rhel8"* ]] || [[ "$distribution"  = "centos"* ]]; then
            dnf module install -y container-tools 1> /dev/null && \
            echo -e "\e[32m**************PODMAN install SUCCESS! **************" || echo -e "\e[31m--------------PODMAN install FAILED! --------------"
            tput sgr0
        fi

    else
        echo -e "\e[32m**************PODMAN is already installed. **************" 
        tput sgr0
    fi
}

install_nvidia_toolkit() {
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

        echo -e "\e[32mInstalling NVIDIA Container Toolkit"
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
        && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
        apt-get update -y > /dev/null && \
        apt-get install -y nvidia-container-toolkit 1> /dev/null && \
        nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml > /dev/null && \
        echo -e "\e[32m**************NVIDIA Container Toolkit install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA Container Toolkit install FAILED! --------------"
        tput sgr0
        
    elif  [[ "$distribution"  = "rhel8"* ]] || [[ "$distribution"  = "centos"* ]]; then
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
        yum install -y nvidia-container-toolkit 1> /dev/null && \
        nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml > /dev/null && \
        echo -e "\e[32m**************NVIDIA Container Toolkit install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA Container Toolkit install FAILED! --------------"
        tput sgr0

    else
        echo  "Local OS is not supported. Please install latest version of Podman, NVIDIA DRIVERS v${NVIDIA_DRIVER_BRANCH} and NVIDIA Container Toolkit"
        tput sgr0
        exit 1
    fi

}

test_nvidia_toolkit() {

        echo -e "\e[32mTesting NVIDIA container toolkit"
        if podman run --rm --security-opt=label=disable --device=nvidia.com/gpu=all ubuntu nvidia-smi 2>&1 | grep -i -q "error" ;then
            echo -e "\e[31m-------------- Test workload run FAILED! Please reboot the VM and run the command 'sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml'. Rerun this script afterwards --------------"
            tput sgr0
            exit 1
        fi
        echo -e "\e[32m************** Sample workload ran succesfully **************"
        tput sgr0
        
}



Main() {

    if [[ "$CV_ENV" == "cpu" ]]; then
        base_prereqs
        install_podman              
    elif [[ "$CV_ENV" == "gpu" ]]; then
        base_prereqs
        check_secure_boot
        checking_nvidia_gpu
        install_nvidia_driver
        install_podman
        install_nvidia_toolkit
        test_nvidia_toolkit
        echo -e "\e[32m************** ALL PREREQUISITES INSTALLED SUCCESSFULLY! **************"
        tput sgr0
    else
        usage
        exit 1
    fi

}

Main