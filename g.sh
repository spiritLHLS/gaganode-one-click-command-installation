#!/bin/bash
# FROM 
# https://github.com/spiritLHLS/gaganode-one-click-command-installation

utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
  echo "No UTF-8 locale found"
else
  export LC_ALL="$utf8_locale"
  export LANG="$utf8_locale"
  export LANGUAGE="$utf8_locale"
  echo "Locale set to $utf8_locale"
fi

myvar=$(pwd)
red(){ echo -e "\033[31m\033[01m$1$2\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1$2\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$1$2\033[0m"; }
reading(){ read -rp "$(green "$1")" "$2"; }
check_root(){
  [[ $(id -u) != 0 ]] && red " The script must be run as root, you can enter sudo -i and then download and run again." && exit 1
}

check_operating_system(){
  CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)"
       "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)"
       "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)"
       "$(grep . /etc/redhat-release 2>/dev/null)"
       "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')"
      )
  for i in "${CMD[@]}"; do SYS="$i" && [[ -n $SYS ]] && break; done
  REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|amazon linux|alma|rocky")
  RELEASE=("Debian" "Ubuntu" "CentOS")
  PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update")
  PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install")
  PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove")
  for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && break
  done
  [[ -z $SYSTEM ]] && red " ERROR: The script supports Debian, Ubuntu, CentOS or Alpine systems only.\n" && exit 1
}

check_virt(){
    architecture=$(uname -m)
    case "$architecture" in
        "armv7l" | "armv6l" | "armv5l" | "armv7" | "armv6" | "armv5")
            ARCH="arm32"
            ;;
        "aarch64")
            ARCH="arm64"
            ;;
        "x86_64" | "x64")
            ARCH="amd64"
            ;;
        "i686")
            ARCH="386"
            ;;
        *)
            ARCH="amd64"
            ;;
    esac
}

input_token(){
  [ -z $token ] && reading " Enter your Token, if you do not find it, open https://dashboard.gaganode.com/register?referral_code=smowgcziqyrfhpo to find it: " token
}

uninstall(){
    check_virt
    if [[ $ARCH == "amd64" ]]; then
        apphub_name="apphub-linux-amd64"
    elif [[ $ARCH == "arm64" ]]; then
        apphub_name="apphub-linux-arm64"
    elif [[ $ARCH == "386" ]]; then
        apphub_name="apphub-linux-386"
    elif [[ $ARCH == "arm32" ]]; then
        apphub_name="apphub-linux-arm32"
    fi
    cd ${myvar}/${apphub_name}
    sudo ./apphub service remove
    cd ..
    rm -rf ${myvar}/${apphub_name}
    exit 1
}

result(){
  green " Finish \n"
}

while getopts "UuT:t:" OPTNAME; do
  case "$OPTNAME" in
    'U'|'u' ) uninstall;;
    'T'|'t' ) token=$OPTARG;;
  esac
done

# 主程序
check_root
check_operating_system
check_virt
input_token
if [ $SYSTEM = "CentOS" ]; then
    yum update
    yum install -y curl tar ca-certificates sudo 
else
    apt-get update
    apt-get install -y curl tar ca-certificates sudo 
fi
timeout=60
interval=3
elapsed_time=0
if [[ $ARCH == "amd64" ]]; then
    curl -o apphub-linux-amd64.tar.gz https://assets.coreservice.io/public/package/60/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz && tar -zxf apphub-linux-amd64.tar.gz && rm -f apphub-linux-amd64.tar.gz
    cd ${myvar}/apphub-linux-amd64
elif [[ $ARCH == "arm64" ]]; then
    curl -o apphub-linux-arm64.tar.gz https://assets.coreservice.io/public/package/61/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz && tar -zxf apphub-linux-arm64.tar.gz && rm -f apphub-linux-arm64.tar.gz
    cd ${myvar}/apphub-linux-arm64
elif [[ $ARCH == "386" ]]; then
    curl -o apphub-linux-386.tar.gz https://assets.coreservice.io/public/package/70/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz && tar -zxf apphub-linux-386.tar.gz && rm -f apphub-linux-386.tar.gz
    cd ${myvar}/apphub-linux-386
elif [[ $ARCH == "arm32" ]]; then
    curl -o apphub-linux-arm32.tar.gz https://assets.coreservice.io/public/package/72/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz && tar -zxf apphub-linux-arm32.tar.gz && rm -f apphub-linux-arm32.tar.gz
    cd ${myvar}/apphub-linux-arm32
fi
sudo ./apphub service remove && sudo ./apphub service install
sudo ./apphub service start
sleep 5
while [ $elapsed_time -lt $timeout ]; do
    status=$(sudo ./apphub status)
    if [[ "$status" == *RUNNING* ]]; then
        break
    fi
    echo "Waiting for the program to start up..."
    echo "${status}"
    sleep $interval
    elapsed_time=$((elapsed_time + interval))
done
sudo ./apps/gaganode/gaganode config set --token=${token}
sleep 1
sudo ./apphub restart
result
