#!/bin/bash

exec > >(tee -i AIF-log.txt)

###############################
# Global variable declaration #
###############################

#update this variable with the NVIDIA driver branch that you want to install on Ubuntu (RHEL installations will use the latest available driver)
NVIDIA_DRIVER_BRANCH='535'

#these variables hold the results of the prereq check, so that the script will only install the missing prereqs
IS_OS_SUPPORTED=false
IS_SECURE_BOOT_ENABLED=false
IS_BASE_PREREQ_INSTALLED=false
IS_NVIDIA_HW_PRESENT=false
IS_NVIDIA_DRIVER_INSTALLED=false
IS_NVIDIA_TOOLKIT_INSTALLED=false
IS_CHECKONLY=false
DO_INSTALL=false
CONTAINER_ENGINE='podman'

#variables that hold the distribution and architecture of the OS
distribution=na
ARCH=na
rheldistro=na #we need an extra variable for RedHat, to build the download link for CUDA
################################


usage() {
    cat <<EOF
usage: $0 options

OPTIONS:
   --check              Check the SW prerequisites for running UiPath CV in one of the modes: gpu or cpu
   --env                Install the SW prerequisites for running UiPath CV in one of the modes: gpu or cpu
   --h                  Show this help

Examples: 
    $0 --env gpu
    $0 --check gpu
    
EOF
}


optspec=":h:-:"
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                check)
                    CV_ENV="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    IS_CHECKONLY=true
                    ;;
                env)
                    CV_ENV="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    DO_INSTALL=true
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

check_os(){
#function that checks the distribution and determines if it's in the supported list
    
    supported_os_list=("rhel8."* "rhel9."* "ubuntu2"*)
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    ARCH=$(/bin/arch)

    for i in "${supported_os_list[@]}"
    do
        if [[ "$distribution" == $i ]]; then
            IS_OS_SUPPORTED=true
        fi
    done
}

check_secure_boot(){
#function that checks if Secure Boot is enabled. This script cannot install NVIDIA drivers on Secure Boot enabled machines
    if ! [[ -x "$(command -v mokutil)" ]]; then
        if [[ "$distribution"  = "ubuntu"* ]]; then
            apt-get update > /dev/null 2>&1
            apt-get upgrade -y > /dev/null 2>&1
            apt-get install -y mokutil > /dev/null 2>&1
        elif  [[ "$distribution"  = "rhel"* ]]; then
            yum update -y  > /dev/null 2>&1
            yum install -y mokutil > /dev/null 2>&1
        fi
    fi
    if mokutil --sb-state | grep enabled; then
        IS_SECURE_BOOT_ENABLED=true    
    fi
}

check_nvidia_gpu() {
#function that checks if a NVIDIA GPU is present

    if lspci | grep -i 'nvidia'; then
        IS_NVIDIA_HW_PRESENT=true
    fi

}

check_base_sw_prereqs(){
#function that checks the basic SW prereqs: 
#  wget
#  lspci
#  podman


    if [[ -x "$(command -v wget)" ]] && [[ -x "$(command -v lspci)" ]] && [[ -x "$(command -v ${CONTAINER_ENGINE})" ]]; then
# podman)" ]] && [[ "$distribution"  = "rhel"* ]] ) || ([[ -x "$(command -v docker)" ]] && [[ "$distribution"  = "ubuntu"* ]])); then
       IS_BASE_PREREQ_INSTALLED=true 
    fi

}

check_nvidia_driver(){
#function that checks if the NVIDIA GPU driver is installed

    if  `which nvidia-smi > /dev/null 2>&1`; then
        IS_NVIDIA_DRIVER_INSTALLED=true
    fi
}

check_nvidia_toolkit(){
#function that checks if the NVIDIA Container Runtime is installed

    if  `which nvidia-container-runtime > /dev/null 2>&1`; then
        test_nvidia_toolkit
    fi
    
}

check_prerequisites(){
#function that runs a check of all the prereqs needed to deploy computer vision

#OS check
    echo -e "Checking for OS version..."
    check_os  #checks if the OS is supported
    if [ "$IS_OS_SUPPORTED" = false ] ; then
        echo -e "\e[31m[FATAL]\e[0m OS not supported. Found ${distribution}. Expected rhel8.*, rhel9.*, ubuntu20.10 or ubuntu22.10."
    else
        echo -e "\e[32m[PASS]\e[0m Supported OS found - ${distribution}."
    fi

#NVIDIA HW check - only do this if --env is set to GPU
    if [ "$CV_ENV" = "gpu" ]; then
        echo -e "Checking for NVIDIA GPU..."
        check_nvidia_gpu #check for the presence of NVIDIA GPU
        if [ "$IS_NVIDIA_HW_PRESENT" = false ]; then
            echo -e "\e[31m[FATAL]\e[0m No NVIDIA GPU found."
        else
        echo -e "\e[32m[PASS]\e[0m NVIDIA GPU present" 
        fi
    fi

#Unsupported OS or absence of NVIDIA HW are fatal errors. The script will not continue and will exit.
    if [ "$IS_OS_SUPPORTED" = false ] || ([ "$CV_ENV" = "gpu" ] && [ "$IS_OS_SUPPORTED" = false ]); then
        echo -e "\e[31m[FATAL]\e[0m Computer Vision installation cannot be performed on this system. Please ensure you are using a system running a supported OS and have a NVIDIA GPU installed. For details, plase see https://docs.uipath.com/ai-computer-vision/standalone. Exiting..."
        exit 1
    fi

#If the OS is supported and we have NVIDIA HW present for --env gpu, we run the remaining checks

#Container Engine is Podman for RHEL and Docker for Ubuntu
    if [[ "$distribution"  = "ubuntu"* ]]; then
        CONTAINER_ENGINE="docker"
    fi



#Checking the presence of the basic SW prereqs.
    echo -e "Checking if wget, lspci and ${CONTAINER_ENGINE} are installed..."
    check_base_sw_prereqs #check whether wget, lspci and podman/docker are present
    if [ "$IS_BASE_PREREQ_INSTALLED" = false ]; then
        echo -e "\e[31m[Missing]\e[0m wget, lspci and/or ${CONTAINER_ENGINE} are missing."
    else 
        echo -e "\e[32m[PASS]\e[0m wget, lspci and ${CONTAINER_ENGINE} are present on the machine"
    fi  

#Following checks are only relevant if --env is set to GPU

    if [ "$CV_ENV" = "gpu" ]; then
    #Checking status of secure boot
        echo -e "Checking status of Secure Boot..."
        check_secure_boot #checks if Secure Boot is enabled. This script cannot install NVIDIA drivers on Secure Boot enabled machines
    
        #The script cannot install the NVIDIA Driver on machine with Secure Boot enabled. If Secure Boot is enabled, we will prompt the user and exit.
        if [ "$IS_SECURE_BOOT_ENABLED" = true ]; then
            echo -e "\e[31m[FATAL]\e[0m Secure Boot is enabled. This script cannot install the NVIDIA driver when Secure Boot is enabled. Please disable Secure Boot and try again. Exiting..."
            exit 1
        else
            echo -e "\e[32m[PASS]\e[0m Secure Boot disabled" 
        fi

    #Checking if the NVIDIA driver is already present
        echo -e "Checking if the NVIDIA driver is already installed..."
        check_nvidia_driver #check if the NVIDIA driver is installed
        if [ "$IS_NVIDIA_DRIVER_INSTALLED" = false ]; then
            echo -e "\e[31m[Missing]\e[0m NVIDIA driver is not present on the system"
        else
            echo -e "\e[32m[PASS]\e[0m NVIDIA Driver already installed."
        #If NVIDIA driver is installed, we are checking if the toolikit is also installed
            echo -e "Checking the NVIDIA container toolkit is already installed..."
            check_nvidia_toolkit #checks if the NVIDIA toolkit is installed. In case it is installed, it tests it by running nvidia-smi in a container
            if [ "$IS_NVIDIA_TOOLKIT_INSTALLED" = false ]; then
                echo -e "\e[31m[Missing]\e[0m NVIDIA container toolkit is not present on the system"
            else
                echo -e "\e[32m[PASS]\e[0m NVIDIA container toolkit is already installed."
            fi
        fi
    fi
}

install_base_prereqs() {

#function that installs the base software prerequisites:
# lspci
# wget
# podman (RHEL) or Docker(Ubuntu)

#setting NEEDRESTART_MODE=a for Ubuntu needrestart, to suppres auto restart services prompt on apt-get upgrade - https://askubuntu.com/questions/1367139/apt-get-upgrade-auto-restart-services

    if [[ "$distribution"  = "ubuntu"* ]]; then
        export NEEDRESTART_MODE=a
    fi

echo "Installing missing base prerequisites (lspci, wget and/or ${CONTAINER_ENGINE}). Please be patient..."

# pciutils and wget are not installed on some default images ( ex.: AWS marketplace image)

    if [[ "$distribution"  = "ubuntu"* ]]; then

    #To support unbuntu 20.04 and 22.04, we need to use docker, as the official repos don't contain a package with the podman version needed to run the nvidia container toolkit

        # Add Docker's official GPG key:
        apt-get update -qq -y 1>/dev/null 
        apt-get install -qq -y ca-certificates curl 1>/dev/null && \
        install -m 0755 -d /etc/apt/keyrings 1>/dev/null && \
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc 1>/dev/null && \
        chmod a+r /etc/apt/keyrings/docker.asc && \
 
        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get -qq -y update 1>/dev/null
 
        #Install base prereqs
        apt-get install -qq -y pciutils wget docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 1> /dev/null && \
        echo -e "\e[32m[Success]\e[0m lspci, wget and docker installed succesfully." || \
        { echo -e "\e[31m[Failed]\e[0m Installation of lspci, wget and/or docker failed. Please manually install these packages and rerun the script. Exiting..."; exit 1; }

        #Test Docker Engine installation
        echo "Checking if docker engine installation is succesfull..."
        docker run hello-world  && \
        echo -e "\e[32m[Success]\e[0m Docker Engine runs succesfully" || \
        { echo -e "\e[31m[Failed]\e[0m Docker Engine test run failed. Please manually install Docker Engine and run the script again. Exiting..."; exit 1; }
    elif  [[ "$distribution"  = "rhel"* ]]; then
    
    #For RHEL, we will install Podman instead of Docker

         dnf update -y  1> /dev/null
         dnf install -y pciutils wget 1> /dev/null && \
         dnf install -y podman 1> /dev/null && \
         echo -e "\e[32m[Success]\e[0m lspci, wget and podman installed succesfully." || \
         { echo -e "\e[31m[Failed]\e[0m Installation of lspci, wget and/or podman failed. Please manually install these packages and rerun the script. Exiting..."; exit 1; }
    else
        echo  "Local OS is not supported. Please install latest version of Podman, NVIDIA drivers and NVIDIA container toolkit"
        tput sgr0
        exit 1
    fi
}


install_nvidia_driver() {
#Function that installs the NVIDIA drivers
#On Ubuntu installations, we need to rely on the NVIDIA_DRIVER_BRANCH variable, to select the driver version
#RHEL installations will install the latest NVIDIA driver available

    echo -e "Installing NVIDIA DRIVERS. Please be patient..."
    echo 'blacklist nouveau' >> /etc/modprobe.d/disable-nouveau.conf
    rmmod nouveau  || true  
    if [[ "$distribution"  = "ubuntu"* ]]; then
    
        # Installing current supported LTS Nvidia Driver Brach
        apt-get -y update 1> /dev/null
        apt-get install -y nvidia-driver-${NVIDIA_DRIVER_BRANCH}-server 1> /dev/null && \
        echo -e "Finished installing server drivers. Installing NVIDIA utils"
        apt-get install -y nvidia-utils-${NVIDIA_DRIVER_BRANCH}-server 1> /dev/null && \
        IS_NVIDIA_DRIVER_INSTALLED=true && \
        install_nvidia_toolkit && \
        echo -e "\e[32m[Success]\e[0m NVIDIA drivers installed." || echo -e "\e[31m[Failure]\e[0m NVIDIA drivers install FAILED!"
        tput sgr0

    elif  [[ "$distribution"  = "rhel"* ]]; then
        if [[ "$distribution"  = "rhel8"* ]]; then
            rheldistro=rhel8
            echo "  Enabling EPEL repos" && \
            dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm 1> /dev/null
        elif [[ "$distribution"  = "rhel9"* ]]; then
            rheldistro=rhel9
            echo "  Enabling EPEL repos" && \
            dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm 1> /dev/null
        fi
        dnf config-manager --add-repo=https://developer.download.nvidia.com/compute/cuda/repos/${rheldistro}/${ARCH}/cuda-${rheldistro}.repo
        echo "  Installing kernel headers and development packages for kernel version $(uname -r)" && \
        dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) 1> /dev/null && \
        dnf module install -y nvidia-driver:latest-dkms 1> /dev/null && \
        IS_NVIDIA_DRIVER_INSTALLED=true && \
        install_nvidia_toolkit && \
        echo -e "\e[32m[Success]\e[0m NVIDIA drivers installed." || echo -e "\e[31m[Failure]\e[0m NVIDIA drivers install FAILED!"
        tput sgr0
    fi    
}

install_nvidia_toolkit() {

#Function that installs the NVIDIA Container Toolkit

    #checking if the NVIDIA driver is correctly installed
    if  ! `which nvidia-smi > /dev/null 2>&1`; then
          echo -e "\e[31m[Error]\e[0m NVIDIA drivers not detected. Please reboot your machine and run the script again." 
          tput sgr0
          exit 1
    fi

    echo -e "Installing NVIDIA container toolkit. Please be patient..."

#Ubuntu installations rely on Docker as a container engine
    if [[ "$distribution"  = "ubuntu"* ]]; then

        echo -e "Installing NVIDIA Container Toolkit. Please be patient..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
        && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
        apt-get update -y 1> /dev/null
        apt-get install -y nvidia-container-toolkit 1> /dev/null && \
        nvidia-ctk runtime configure --runtime=docker 1> /dev/null && \
        systemctl restart docker 1> /dev/null && \
        test_nvidia_toolkit && \
        echo -e "\e[32m[Success]\e[0m NVIDIA Container Toolkit installed." || echo -e "\e[31m[Failure]\e[0m NVIDIA Container Toolkit install FAILED!"
        tput sgr0
        
#On RHEL installations, we have Podman as a container egnine
    elif  [[ "$distribution"  = "rhel"* ]]; then
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
        yum install -y nvidia-container-toolkit 1> /dev/null && \
        nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml > /dev/null 
        test_nvidia_toolkit && \
        echo -e "\e[32m[Success]\e[0m NVIDIA Container Toolkit installed." || echo -e "\e[31m[Failure]\e[0m NVIDIA Container Toolkit install FAILED!"
        tput sgr0
    fi
}

test_nvidia_toolkit() {
#Function for testing if the NVIDIA Container Toolkit is correctly installed.
#This test is performed by running a test container and running nvidia-smi inside of it
#Ubuntu uses Docker as Container Engine, while RHEL uses Podman

        echo -e "Testing NVIDIA container toolkit"

        if [[ CONTAINER_ENGINE = "docker" ]]; then
            if docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi 2>&1 | grep -i -q "error" ;then
                echo -e "\e[31m[Failure]\e[0m Test workload run FAILED! Please reboot the VM and run the command 'sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker'. Rerun this script afterwards"
                tput sgr0
                exit 1
            fi
        elif podman run --rm --security-opt=label=disable --device=nvidia.com/gpu=all ubuntu nvidia-smi 2>&1 | grep -i -q "error" ;then
            echo -e "\e[31m[Failure]\e[0m Test workload run FAILED! Please reboot the VM and run the command 'sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml'. Rerun this script afterwards"
            tput sgr0
            exit 1
        fi
        IS_NVIDIA_TOOLKIT_INSTALLED=true
        echo -e "\e[32m[Success]\e[0m Sample workload ran succesfully."
        tput sgr0
        
}


install_prereqs(){
#Function that handles the installation of missing prerequisites
    
    if [ "$IS_BASE_PREREQ_INSTALLED" = false ]; then
        install_base_prereqs
    fi
    if [ "$CV_ENV" = "gpu" ]; then
        if [ "$IS_NVIDIA_DRIVER_INSTALLED" = false ]; then
            install_nvidia_driver
        fi
        if [ "$IS_NVIDIA_TOOLKIT_INSTALLED" = false ]; then
            install_nvidia_toolkit
        fi
    fi
    echo -e "\e[32mAll prerequisites are installed. You can proceed to run UiPath Computer Vision on this machine."
    tput sgr0
}

Main(){

#If the parameters aren't CPU or GPU, we display the usage and exit

    if [ "$CV_ENV" != "cpu" ] && [ "$CV_ENV" != "gpu" ]; then
        usage
        exit 1
    fi
#The prereq check will run regardless of whether we ran the check or the env command; we will do a prereq check for installs as well

    echo "Checking prerequisites for running UiPath Computer Vision on ${CV_ENV}"
    check_prerequisites
    echo "Prerequisites check completed."
    #Checking if the prerequisites are already installed and exiting if they are.
    if ( [ "$CV_ENV" = "cpu" ] && [ "$IS_BASE_PREREQ_INSTALLED" = true ] ) || ( [ "$CV_ENV" = "gpu" ] && [ "$IS_BASE_PREREQ_INSTALLED" = true ] && [ "$IS_NVIDIA_DRIVER_INSTALLED" = true ] && [ "$IS_NVIDIA_TOOLKIT_INSTALLED" = true ] ); then
        echo -e "\e[32mAll prerequisites are installed. You can proceed to run UiPath Computer Vision on this machine."
        tput sgr0
        exit 0
    fi
    
    if [ "$IS_CHECKONLY" = true ]; then
    #Checking if the user wants to also install the missing prereqs. If the user chooses n, we will exit. If the user chooses y, the script continues and installs the prereq
        while true
        do
            read -p "Would you like to install the missing prerequisites? [y/n] " -n 1 -r continue
            case "$continue" in
                n|N)
                     echo 
                     exit 
                    ;;
                y|Y) 
                     echo
                     break               
                    ;;
                *) echo 'Response not valid';;
            esac
        done
    fi
    install_prereqs
}

Main