#!/bin/bash
###############################################################################
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2022. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
###############################################################################
# CUR_DIR set to full path to scripts folder
CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CUR_DIR}/helper/common.sh

function select_uninstall_type(){
    local returnValue
       kubectl get subscription -n $NAMESPACE | grep ibm-fncm-operator >/dev/null 2>&1
    returnValue=$?
    if [ "$returnValue" == 0 ] ; then
        uninstall_olm_fncm
    elif [ "$returnValue" == 1 ] ; then
        uninstall_cncf_fncm
    fi
}

function uninstall_cncf_fncm(){
    printf "\n"
    printf "\x1B[1mUninstall IBM FileNet Content Manager Operator...\n\x1B[0m"
    kubectl delete -f ${CUR_DIR}/../descriptors/operator.yaml -n $NAMESPACE >/dev/null 2>&1
    kubectl delete -f ${CUR_DIR}/../descriptors/role_binding.yaml -n $NAMESPACE >/dev/null 2>&1
    kubectl delete -f ${CUR_DIR}/../descriptors/role.yaml -n $NAMESPACE >/dev/null 2>&1
    kubectl delete -f ${CUR_DIR}/../descriptors/service_account.yaml -n $NAMESPACE >/dev/null 2>&1
    echo "All descriptors have been successfully deleted."
}

function uninstall_olm_fncm(){
    local csvName
    printf "\n"
    printf "\x1B[1mUninstall IBM FileNet Content Manager Operator Subscription...\n\x1B[0m"
    csvName=$(kubectl get subscription ibm-fncm-operator -n $NAMESPACE -o go-template --template '{{.status.installedCSV}}')
    # - remove the subscription
    kubectl delete subscription ibm-fncm-operator -n $NAMESPACE >/dev/null 2>&1
    # - remove the CSV which was generated by the subscription but does not get garbage collected
    kubectl delete clusterserviceversion "${csvName}" >/dev/null 2>&1
    echo "The IBM FileNet Content Manager Operator Subscription has been successfully deleted."
}

function show_help {
    echo -e "\nPrerequisite:"
    echo -e "1. Login your cluster;"
    echo -e "2. CR was applied in your project."
    echo -e "Usage for other platform: deleteOperator.sh -n namespace\n"
    echo "Options:"
    echo "  -h  Display help"
    echo "  -n  The namespace to delete Operator"
}

if [[ $1 == "" ]]
then
    show_help
    exit -1
else
    while getopts "h?n:" opt; do
        case "$opt" in
        h|\?)
            show_help
            exit 0
            ;;
        n) NAMESPACE=$OPTARG
            ;;
        :)  echo "Invalid option: -$OPTARG requires an argument"
            show_help
            exit -1
            ;;
        esac
    done
fi

select_uninstall_type

