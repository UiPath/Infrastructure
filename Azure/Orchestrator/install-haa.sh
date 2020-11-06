#!/bin/bash

echo -e "\e[32mConfiguring High Availability Add-On for Orchestrator"
# tput sgr0
usage() {
    cat <<EOF
usage: $0 options
Examples: $0 -u user@company.net -p my_password -j 10.10.22.10
OPTIONS:
   -u              Username
   -p              Password
   -d	           DNS
   -j              Master node IP. If this is specified, then the node is created as slave node.
   -h              Show this help
   -l              License code.
   --advanced      Installs HAA in advanced mode with more optional arguments. This optional argument won't configure the cluster or join any node to existing cluster.
   --verbose       Verbose mode.
EOF
}

optspec="hu:p:j:l:d:-:"
# set initial values
VERBOSE=false
ADVANCED=false
while getopts "$optspec" option; do
    case "${option}" in
        
        h) usage exit 1 ;;
        u) USERNAME=${OPTARG} ;;
        p) PASSWORD=${OPTARG} ;;
		d) DNS=${OPTARG} ;;
        j) CLUSTER=${OPTARG} ;;
        l) LICENSE=${OPTARG} ;;
        w) WEBLINK=${OPTARG} ;;
        -)
            case "${OPTARG}" in
                verbose)
                    VERBOSE=true
                    ;;
                advanced)
                    ADVANCED=true
                    ;;
                *)
                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}" >&2
                    fi
                    ;;
            esac;;
        ?) usage exit 1 ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
                exit 2
            fi
            ;;
    esac
done

download_haa(){
echo -e "\e[32mDownloading High Availability Add-On for Orchestrator"
wget $WEBLINK 1> /dev/null
# tput sgr0
tar -xf haa-2.0.0.tar.gz
chmod a+x install.sh
}

if [[ "$ADVANCED" == "true" ]]; then
    download_haa
    echo "Advanced mode selected, please run ./install.sh with optional argumets provided in this help."
    echo "install.sh: this script installs HAA UiPath pack on the node. When no options are provided, install.sh runs in the interactive mode."
    echo "install.sh [-y] [-c <answer-file>] [-s <socket-path>]"
    echo "  -y Answer 'yes' for all questions instead of awaiting user input."
    echo "  -c <answer-file> Provide a path to the answer-file to modify the installation options."
    echo "  -s <socket-directory> Provide a directory for HAA UiPath unix sockets. This is supported only on a fresh install, not in upgrade."
    echo "  --install-dir <dir> Provide a path to install HAA UiPath. This is supported only on a fresh install, not in upgrade."
    echo "  --config-dir <dir> Provide a path for the configuration directory for HAA UiPath installation. This is supported only on a fresh install, not in upgrade."
    echo "  --var-dir <dir> Provide a var_dir for HAA UiPath installation. This is supported only on a fresh install, not in upgrade."
    echo "  --os-user <user> Provide os user for HAA UiPath installation (default - uipath). This is supported only on a fresh install, not in upgrade."
    echo "  --os-group <group> Provide os group for HAA UiPath installation (default - uipath). This is supported only on a fresh install, not in upgrade."
    echo "Usage examples:"
    echo "  ./install.sh -y"
    echo "  ./install.sh -c answer.file"
    echo "  ./install.sh -s /var/run/haa-uipath"
    exit 1
fi

if [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
    usage
    exit 1
fi
email_regex="\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b"
if [[ $USERNAME =~ $email_regex ]]; then
    continue
else
    usage
    exit 1
fi

download_haa

echo -e "\e[32mInstalling High Availability Add-On for Orchestrator"
if [[ "$VERBOSE" == "true" ]]; then
    bash ./install.sh -y
else
    bash ./install.sh -y 1> /dev/null
fi

post_create_db(){
    cat<<EOF
{
    "name": "uipath-orchestrator",
    "type": "redis",
    "memory_size": 2147483648,
    "port" : 10000,
    "slave_ha": true,
    "authentication_redis_pass": "${PASSWORD}",
    "uid": 3
}
EOF
}

put_update_db(){
    cat<<EOF
{
    "replication": true
}
EOF
}

post_create_cluster(){
    cat<<EOF
{
    "action": "create_cluster",
    "cluster": {
       "nodes": [],
       "name": "${DNS:=uipath.cluster}"
    },
    "credentials": {
       "username": "${USERNAME}",
       "password": "${PASSWORD}"
    }
}
EOF
}

post_join_cluster(){
    cat<<EOF
{
    "action": "join_cluster",
    "cluster": {
       "nodes": ["${CLUSTER}"],
       "name": "${DNS:=uipath.cluster}"
    },
    "credentials": {
       "username": "${USERNAME}",
       "password": "${PASSWORD}"
    }
}
EOF
}

put_license() {
    cat <<EOF
{
    "license": "----- LICENSE START -----\n${LICENSE}\n----- LICENSE END -----\n"
}
EOF
}

if [[ -z "$CLUSTER" ]]; then
    echo -e "\e[32mThis node will be the master node."
    echo -e "\e[32mCreating cluster..."
    # tput sgr0
    curl -k -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "$(post_create_cluster)" "https://127.0.0.1:9443/v1/bootstrap/create_cluster"
    echo -e "\e[32mCreating UiPath database..."
    # tput sgr0
    sleep 30s
    curl -u "${USERNAME}:${PASSWORD}" -k -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "$(post_create_db)" "https://127.0.0.1:9443/v1/bdbs"
    
else
    echo -e "\e[32mJoining node to cluster... " $CLUSTER
    # tput sgr0
    curl -k -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "$(post_join_cluster)" "https://127.0.0.1:9443/v1/bootstrap/join_cluster"
    sleep 10s
    echo -e "\e[32mActivating DB Replication..."
    # tput sgr0
    curl -u "${USERNAME}:${PASSWORD}" -k -i -H "Accept: application/json" -H "Content-Type:application/json" -X PUT --data "$(put_update_db)" "https://${CLUSTER}:9443/v1/bdbs/3"
fi

if [[ ! -z "$LICENSE" ]]; then
    
    curl -u "${USERNAME}:${PASSWORD}" -k -i -H "Accept: application/json" -H "Content-Type:application/json" -X PUT --data "$(put_license)" "https://127.0.0.1:9443/v1/license"
    
fi

echo -e "\e[32mInstallation and Configuration of High Availability Add-On for Orchestrator is finished."
# tput sgr0