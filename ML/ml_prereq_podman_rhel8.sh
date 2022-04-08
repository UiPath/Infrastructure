distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
ARCH=$(/bin/arch)
NVIDIA_DRIVER_VERSION="460"

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

base_prereqs() {
    if [[ -x "$(command -v wget)" ]] && [[ -x "$(command -v lspci)" ]]  ; then
        return
    fi        

    sudo yum update -y  
    sudo yum install -y pciutils wget
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

install_podman() {

    if ! [ -x "$(command -v podman)" ]; then
        echo -e "\e[31m--------------PODMAN is not installed! --------------"
        tput sgr0        
        echo -e "\e[32mInstalling PODMAN"
        dnf module install -y container-tools
        echo -e "\e[32m**************PODMAN install SUCCESS! **************"
    else
        echo -e "\e[32m**************PODMAN is already installed. **************" 
        tput sgr0
    fi

}

install_nvidia_driver(){
    #echo 'blacklist nouveau' >> /etc/modprobe.d/disable-nouveau.conf //
    #rmmod nouveau  || true  //
    echo -e "\e[32mInstalling NVIDIA DRIVERS"
    dnf config-manager --add-repo=https://developer.download.nvidia.com/compute/cuda/repos/rhel8/${ARCH}/cuda-rhel8.repo
    dnf module install -y nvidia-driver:${NVIDIA_DRIVER_VERSION}
    echo -e "\e[32m**************NVIDIA Driver install SUCCESS! **************"
    tput sgr0
}

install_nvidia_container_toolkit(){
    echo -e "\e[32mInstalling NVIDIA Container Toolkit"
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    sudo dnf clean expire-cache && sudo dnf install -y nvidia-container-toolkit && \
    sed -i 's/^#no-cgroups = false/no-cgroups = true/;' /etc/nvidia-container-runtime/config.toml && \
    echo -e "\e[32m**************NVIDIA Container Toolkit install SUCCESS! **************" || echo -e "\e[31m--------------NVIDIA Container Toolkit install FAILED! --------------"
    tput sgr0
}


Main() {
    if [[ "$CV_ENV" == "cpu" ]]; then
        base_prereqs
        install_podman      
    elif [[ "$CV_ENV" == "gpu" ]]; then    
        base_prereqs
        checking_nvidia_gpu
        install_nvidia_driver
        install_podman              
        install_nvidia_container_toolkit
    else
        usage
        exit 1
    fi
}

Main