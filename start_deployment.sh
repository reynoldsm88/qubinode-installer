#!/usr/bin/env bash
# This script will start the automated depoyment of openshift home lab

# Uncomment for debugging
#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
#set -x

function display_help() {
    SCRIPT=$(basename "${BASH_SOURCE[0]}")

    cat << EOH >&2
Basic usage: ${SCRIPT} [options]
    -p      Deploy okd or ocp: default is ocp
                   ---    ---             ---
    -s      Skip DNS server deployment
    -u      Skip creating DNS entries
    -h      Display this help menu
EOH
}

function check_args () {
    if [[ $OPTARG =~ ^-[h/p/u/s]$ ]]
    then
      echo "Invalid option argument $OPTARG, check that each argument has a value." >&2
      exit 1
    fi
}

function deploy_dns_server () {
    if [ "A${skip_dns}" != "Atrue" ]; then
        kvm_inventory=$1
        
        env_check
        validation $2
        addssh
        configurednsforopenshift $2 centos
        configure_dns_for_arecord $2 centos
    else
        # this assumes you are providing your own dns server
        # we need to be able to do a nsupdate against your dns server
        # to verify the required dns entries are available
        echo "Do run fuction to verify dns"
        configure_dns_for_arecord $2 centos
   fi
}

# validate product pass by user
function validate_product_by_user () {
    for item in $(echo "$VALID_PRODUCTS")
    do
        if [ "A${product}" == "A${item}" ];
        then
            product="${product}"
            break
        else
            product="${DEFAULT_PRODUCT}"
        fi
    done
}

config_err_msg () {
    cat << EOH >&2
  Could not find start_deployment.conf in the current path ${project_dir}. 
  Please make sure you are in the openshift-home-lab-directory."
EOH
}

# check for openshift-home-lab-directory and setup paths
function setup_required_paths () {
    current_dir=$(pwd)
    script_dir=$(dirname ${BASH_SOURCE[0]})
    current_dir_config="${current_dir}/inventory/group_vars/all"
    script_dir_config="${script_dir}/inventory/group_vars/all"

    if [ -f "${current_dir_config}" ]; then
        project_dir="${current_dir}"
        config_file="${current_dir_config}"
    elif [ ! -f "${script_dir_config}" ]; then
        project_dir="${script_dir}"
        config_file="${script_dir_config}"
    else
        config_err_msg; exit 1
    fi
}

while getopts ":hip:" opt;
do
    case $opt in
        h) display_help
           exit 1
           ;;
        i) check_args; generate_inventory=true;;
        p) check_args
           product=$OPTARG
           ;;
        s) check_args; skip_dns=true;;
       --) shift; break;;
       -*) echo Unrecognized flag : "$1" >&2
           display_help
           exit 1
           ;;
       \?) echo Unrecognized flag : "$1" >&2
           display_help
           exit 1
           ;;
    esac
done
shift "$((OPTIND-1))"

# validate user provided options
validate_product_by_user
setup_required_paths
   
echo $project_dir
echo $config_file
