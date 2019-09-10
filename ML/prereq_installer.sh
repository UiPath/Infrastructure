#!/bin/bash

#checking  OS
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

if [[ "$distribution" = "rhel7"* ]]; then
    curl -fsSL https://raw.githubusercontent.com/UiPath/Infrastructure/master/ML/ml_prereqs_rhel7.sh | sh
elif  [[ "$distribution"  = "ubuntu"* ]]; then
    curl -fsSL https://raw.githubusercontent.com/UiPath/Infrastructure/master/ML/ml_prereqs_ubuntu16.sh | sh
else
   echo  "local OS is not supported"
   exit 1
fi


