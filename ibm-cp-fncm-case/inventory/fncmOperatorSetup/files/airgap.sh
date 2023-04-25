#!/bin/bash

# Licensed Materials - Property of IBM
# Copyright IBM Corporation 2020. All Rights Reserved
# US Government Users Restricted Rights -
# Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# This is an internal component, bundled with an official IBM product. 
# Please refer to that particular license for additional information. 

# ---------- Command arguments ----------

# log level
LOG_LEVEL=INFO

# registry server
AUTH_REGISTRY_SERVER=

# username for registry authentication
AUTH_REGISTRY_USERNAME=

# password for registry authentication
AUTH_REGISTRY_PASSWORD=

# email for registry authentication
AUTH_REGISTRY_EMAIL=

# the CASE archive directory
CASE_ARCHIVE_DIR=

# the CASE archive name
CASE_ARCHIVE=

# dry-run mode
DRY_RUN=

# dry-run output folder - if not specified, the output will be printed to stdout
DRY_RUN_OUTPUT=

# show registries
SHOW_REGISTRIES=

# show registries and namespaces
SHOW_REGISTRIES_NAMESPACES=

# source image
IMAGE=

# image CSV file
IMAGE_CSV_FILE=

# image content source policy name
IMAGE_POLICY_NAME=

# the source image registry
SOURCE_REGISTRY=

# the target image registry
TARGET_REGISTRY=

# the image groups to filter from mirror
IMAGE_GROUPS=

# the image archs to filter from mirror
IMAGE_ARCHS=

# flag which checks if a filter fails (when no right images present)
FILTER_FAILS=

# skips using image delta if it exists
SKIP_DELTA=

# Boolean toggle to determine if the command called was for mirroring images or not
IMAGE_MIRROR_ACTION_CALLED=

# ---------- Command variables ----------

# data path that keeps the registry authentication secrets
AUTH_DATA_PATH="${HOME}/.airgap"

# namespace action for image mirroring
NAMESPACE_ACTION=

# namespace action value for image mirroring
NAMESPACE_ACTION_VALUE=

# temporary directory path
TMP_DIR_PATH=${TMPDIR:-/tmp}

# temporary file prefix
OC_TMP_PREFIX="airgap"

# temporary csv directory
OC_TMP_CSV_DIR=$(mktemp ${TMP_DIR_PATH}/${OC_TMP_PREFIX}_csv_XXXXXXXXX)

# temporary registry image csv directory
OC_TMP_CSV_REG_DIR=$(mktemp -d ${TMP_DIR_PATH}/${OC_TMP_PREFIX}_csv_reg_XXXXXXXXX)

# temporary image mapping file
OC_TMP_IMAGE_MAP=$(mktemp ${TMP_DIR_PATH}/${OC_TMP_PREFIX}_image_mapping_XXXXXXXXX)

# temporary image mapping file split size
OC_TMP_IMAGE_MAP_SPLIT_SIZE=100

# temporary image content source policy taml
OC_TMP_IMAGE_POLICY=$(mktemp ${TMP_DIR_PATH}/${OC_TMP_PREFIX}_image_policy_XXXXXXXXX)

# temporary cluster pull secret
OC_TMP_PULL_SECRET=$(mktemp ${TMP_DIR_PATH}/${OC_TMP_PREFIX}_pull_secret_XXXXXXXXX)

# debug logging for image mirroring oc command
OC_DEBUG_LOGGING=""

# debug logging for image mirroring skopeo command
SKOPEO_DEBUG_LOGGING=""

# script directory
SCRIPT_DIR=`dirname "$0"`

# script version
VERSION=0.13.8

# --- registry service variables ---

# container engine used to run the registry, either 'docker' or 'podman'
CONTAINER_ENGINE=

# docker registry image
REGISTRY_IMAGE=${REGISTRY_IMAGE:-docker.io/library/registry:2.8.1}

# registry directory
REGISTRY_DIR=${TMP_DIR_PATH}/docker-registry

# registry container name
REGISTRY_NAME=docker-registry

# registry service host
REGISTRY_HOST=$(hostname -f)

# registry service port
REGISTRY_PORT=5000

# registry default account username
REGISTRY_USERNAME=

# registry default account password
REGISTRY_PASSWORD=

# indicates if the registry default account password is generated or not
REGISTRY_PASSWORD_GENERATED=false

# registry reset
REGISTRY_RESET=false

# registry self-sign TLS certificate authority subject
REGISTRY_TLS_CA_SUBJECT="/C=US/ST=New York/L=Armonk/O=IBM Cloud Pak/CN=IBM Cloud Pak Root CA"

# registry self-sign TLS certificate subject
REGISTRY_TLS_CERT_SUBJECT="/C=US/ST=New York/L=Armonk/O=IBM Cloud Pak"

# registry self-sign TLS certificate subject alternative name
REGISTRY_TLS_CERT_SUBJECT_ALT_NAME="subjectAltName=IP:127.0.0.1,DNS:localhost"

# indicates if registry is TLS enabled
REGISTRY_TLS_ENABLED=true

# registry certificate authorities configmap
REGISTRY_CA_CONFIGMAP=airgap-trusted-ca

# https status code allow to enable tls
HTTPS_SUCCESS_CODE=(200 202 301 302 303)

#Skopeo Copy retry count
SKOPEO_RETRY_COUNT="${SKOPEO_COPY_RETRY:=5}"

#Skopeo Retry String
SK_RETRY_STRING=""

#Skopeo preserve digest String
SK_PRESERVE_DIGEST_STRING=""

# ---------- Shared Package Variables ----------
# Context of mirrored image CSV files created
declare -a MIRRORED_IMAGE_CSV_CONTEXT=


# ---------- Command functions ----------

#
# Logging
#
log_debug() {
    case ${LOG_LEVEL} in
    DEBUG)
        echo "[DEBUG] $@" > /dev/stderr
        ;;
    esac
}
log_info() {
    case ${LOG_LEVEL} in
    DEBUG|INFO)
        echo "[INFO] $@" > /dev/stderr
        ;;
    esac
}
log_warn() {
    case ${LOG_LEVEL} in
    DEBUG|INFO|WARN)
        echo "[WARN] $@" > /dev/stderr
        ;;
    esac
}
log_error() {
    echo "[ERROR] $@" > /dev/stderr
}

#
# Main function
#
main() {
    # clean up previous temp files
    find -L ${TMP_DIR_PATH} -type f -name "${OC_TMP_PREFIX}_*" 2> /dev/null -exec rm -f {} 2> /dev/null \;

    # parses command arguments
    parse_arguments "$@"
}

#
# Parses the CLI arguments
#
parse_arguments() {
    if [[ "$#" == 0 ]]; then
        print_usage
        exit 1
    fi

    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        registry)
            shift
            parse_registry_arguments "$@"
            break
            ;;
        image)
            shift
            parse_image_arguments "$@"
            break
            ;;
        cluster)
            shift
            parse_cluster_arguments "$@"
            break
            ;;
        -v | --version)
            print_version
            exit 0
            ;;       
        -h | --help)
            print_usage
            exit 0
            ;;
        *)
            print_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Prints usage menu
#
print_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} [registry|image|cluster]"
    echo ""
    echo "This tool helps mirroring CASE images and updating cluster to support"
    echo "installing IBM Cloud Pak in an Air-Gapped environment"
    echo ""
    echo "Options:"
    echo "   registry          Manage registry authentication secrets"
    echo "   image             Mirroring images from one registry to another"
    echo "   cluster           Configure OpenShift cluster to use with a mirrored registry"
    echo "   -v, --version     Print version information"
    echo "   -h, --help        Print usage information"
    echo ""
}

#
# Prints version 
#
print_version() {
    log_info "Version ${VERSION}"
}

# ---------- Registry functions ----------

#
# Parses argument for 'registry' action
#
parse_registry_arguments() {
    if [[ "$#" == 0 ]]; then
        print_registry_usage
        exit 1
    fi

     # process options
    while [ "$1" != "" ]; do
        case "$1" in
        service)
            shift
            parse_registry_service_arguments "$@"
            break
            ;;
        secret)
            shift
            parse_registry_secret_arguments "$@"
            break
            ;;
        -h | --help)
            print_registry_usage
            exit 1
            ;;
        *)
            print_registry_usage
            exit 1
            ;;
        esac
        shift
    done
}

# Prints usage menu for 'registry' action
#
print_registry_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry [service|secret] [OPTIONS]..."
    echo ""
    echo "Run a private docker registry or manage authentication secrets" 
    echo "for all theregistries used in the image mirroring process."
    echo ""
    echo "Options:"
    echo "  service"
    echo "    init               Initialize a docker registry"
    echo "    start              Start a docker registry service"
    echo "    stop               Stop the running docker registry service"
    echo "  secret"
    echo "    -c, --create       Create an authentication secret"
    echo "    -d, --delete       Delete an authentication secret"
    echo "    -l, --list         List all authentication secrets"
    echo "    -D, --delete-all   Delete all authentication secrets"
    echo "  -h, --help           Print usage information"
    echo ""
}

# ---------- Registry service functions ----------

#
# Initializes docker registry
#
do_registry_service_init() {
    # parses arguments
    parse_registry_service_init_arguments "$@"
    
    # validates arguments
    validate_registry_service_init_arguments

    # validates required tools
    validate_registry_service_init_required_tools
    
    # deletes existing auth directory

    # initializes registry data directory
    log_info "Initializing ${REGISTRY_DIR}/data"
    if [ "${REGISTRY_RESET}" == "true" ] && [ -d "${REGISTRY_DIR}/data}" ]; then
        rm -rf "${REGISTRY_DIR}/data}"
    fi
    mkdir -p "${REGISTRY_DIR}/data"

    # initializes registry auth directory
    log_info "Initializing ${REGISTRY_DIR}/auth"
    if [ -d "${REGISTRY_DIR}/auth" ]; then
        rm -rf "${REGISTRY_DIR}/auth"
    fi
    mkdir -p "${REGISTRY_DIR}/auth"

    # creates registry certs directory
    log_info "Initializing ${REGISTRY_DIR}/certs"
    if [ -d "${REGISTRY_DIR}/certs" ]; then
        rm -rf "${REGISTRY_DIR}/certs"
    fi
    mkdir -p "${REGISTRY_DIR}/certs"

    if [ ! -z "${REGISTRY_USERNAME}" ] && [ ! -z "${REGISTRY_PASSWORD}" ]; then
        # creates htpasswd and add a default account
        log_info "Creating ${REGISTRY_DIR}/auth/htpasswd"
        htpasswd -bBc "${REGISTRY_DIR}/auth/htpasswd" ${REGISTRY_USERNAME} ${REGISTRY_PASSWORD}
    fi

    # prepares for subject subject alternative name
    if [[ ! "${REGISTRY_TLS_CERT_SUBJECT}" =~ .*"CN=".* ]]; then
        REGISTRY_TLS_CERT_SUBJECT="${REGISTRY_TLS_CERT_SUBJECT}/CN=${REGISTRY_HOST}"
    fi

    # records the registry hostname
    if [ ! -z "${REGISTRY_HOST}" ]; then
        echo "${REGISTRY_HOST}" > "${REGISTRY_DIR}/hostname"
    fi

    # prepares for subject alternative name
    if [[ "${REGISTRY_HOST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        REGISTRY_TLS_CERT_SUBJECT_ALT_NAME="${REGISTRY_TLS_CERT_SUBJECT_ALT_NAME},IP:${REGISTRY_HOST}"
    else
        REGISTRY_TLS_CERT_SUBJECT_ALT_NAME="${REGISTRY_TLS_CERT_SUBJECT_ALT_NAME},DNS:${REGISTRY_HOST}"
    fi

    # generates self-sign certificate
    log_info "Generating self-sign certificate"
    openssl genrsa -out "${REGISTRY_DIR}/certs/ca.key" 4096
    openssl req -new -x509 -days 365 -sha256 -subj "${REGISTRY_TLS_CA_SUBJECT}" -key "${REGISTRY_DIR}/certs/ca.key" -out "${REGISTRY_DIR}/certs/ca.crt"
    openssl req -newkey rsa:4096 -nodes -subj "${REGISTRY_TLS_CERT_SUBJECT}" -keyout "${REGISTRY_DIR}/certs/server.key" -out "${REGISTRY_DIR}/certs/server.csr"
    openssl x509 -req -days 365 -sha256 -extfile <(printf "${REGISTRY_TLS_CERT_SUBJECT_ALT_NAME}") \
        -CAcreateserial -CA "${REGISTRY_DIR}/certs/ca.crt" -CAkey "${REGISTRY_DIR}/certs/ca.key" \
        -in "${REGISTRY_DIR}/certs/server.csr"   -out "${REGISTRY_DIR}/certs/server.crt"

    if [[ "${REGISTRY_PASSWORD_GENERATED}" == "true" ]]; then
        log_info "username = ${REGISTRY_USERNAME}"
        log_info "password = ${REGISTRY_PASSWORD}"
    fi
}

#
# Starts the docker registry
#
do_registry_service_start() {
    # parses arguments
    parse_registry_service_start_arguments "$@"

    # validates arguments
    validate_registry_service_start_arguments

    # detects available container engine
    detect_registry_service_container_engine

    # starts registry container
    log_info "Starting registry"
    if [ -f "${REGISTRY_DIR}/auth/htpasswd" ]; then
        ${CONTAINER_ENGINE} run --name "${REGISTRY_NAME}" -p ${REGISTRY_PORT}:5000 --restart=always \
            -v ${REGISTRY_DIR}/data:/var/lib/registry:z \
            -v ${REGISTRY_DIR}/auth:/auth:z \
            -v ${REGISTRY_DIR}/certs:/certs:z \
            -e REGISTRY_AUTH=htpasswd \
            -e REGISTRY_AUTH_HTPASSWD_REALM=RegistryRealm \
            -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt \
            -e REGISTRY_HTTP_TLS_KEY=/certs/server.key \
            -d ${REGISTRY_IMAGE}
    else
        ${CONTAINER_ENGINE} run --name "${REGISTRY_NAME}" -p ${REGISTRY_PORT}:5000 --restart=always \
            -v ${REGISTRY_DIR}/data:/var/lib/registry:z \
            -v ${REGISTRY_DIR}/auth:/auth:z \
            -v ${REGISTRY_DIR}/certs:/certs:z \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt \
            -e REGISTRY_HTTP_TLS_KEY=/certs/server.key \
            -d ${REGISTRY_IMAGE}
    fi

    # checks for return code
    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi

    # grabs the container id
    container_id=$(${CONTAINER_ENGINE} ps -qf "name=${REGISTRY_NAME}")
    if [ ! -z "${container_id}" ]; then
        log_info "Registry service started at ${REGISTRY_HOST}:${REGISTRY_PORT}"
    else
        log_error "Registry service cannot be started"
        exit 11
    fi
}

#
# Stops the docker registry
#
do_registry_service_stop() {
    # parses arguments
    parse_registry_service_stop_arguments "$@"

    # validates arguments
    validate_registry_service_stop_arguments

    # detects available container engine
    detect_registry_service_container_engine

    # grabs the container id
    container_id=$(${CONTAINER_ENGINE} ps -aqf "name=${REGISTRY_NAME}")

    # checks for return code
    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi

    if [ ! -z "${container_id}" ]; then
        log_info "Stopping registry service"
        ${CONTAINER_ENGINE} stop ${container_id}
        ${CONTAINER_ENGINE} rm ${container_id}
        log_info "Registry service stopped"
    else
        log_warn "Registry service already stopped"
    fi
}

#
# Detects available supported container command, such as 'docker' or 'podman'
#
detect_registry_service_container_engine() {
    docker_command=$(command -v docker 2> /dev/null)
    podman_command=$(command -v podman 2> /dev/null)

    if [ ! -z "${CONTAINER_ENGINE}" ]; then
        # handles when container engine is explicitly specified
        if [ "${CONTAINER_ENGINE}" == "podman" ] && [ -x "${podman_command}" ]; then
            CONTAINER_ENGINE=${podman_command}
        elif [ "${CONTAINER_ENGINE}" == "docker" ] && [ -x "${docker_command}" ]; then
            CONTAINER_ENGINE=${docker_command}
        else
            log_error "${CONTAINER_ENGINE} not available on the system"
            exit 1
        fi
    else
        # auto detect available container engine
        if [ -x "${podman_command}" ]; then
            CONTAINER_ENGINE=${podman_command}
        elif [ -x "${docker_command}" ]; then
            CONTAINER_ENGINE=${docker_command}        
        else
            log_error "docker or podman must be available on the system"
            exit 1
        fi
    fi

    log_info "Container engine: ${CONTAINER_ENGINE}"
}

#
# Parses arguments for 'registry service' action
#
parse_registry_service_arguments() {
    if [[ "$#" == 0 ]]; then
        print_registry_service_usage
        exit 1
    fi

    while [[ "$1" != "" ]]; do
        case "$1" in
        init)
            shift
            do_registry_service_init "$@"
            break
            ;;
        start)
            shift
            do_registry_service_start "$@"
            break
            ;;
        stop)
            shift
            do_registry_service_stop "$@"
            break
            ;;
        -h | --help)
            print_registry_service_usage
            exit 1
            ;;
        *)
            print_registry_service_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses arguments for 'registry service init' action
#
parse_registry_service_init_arguments() {
    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        -d | --dir)
            shift
            REGISTRY_DIR="$1"
            ;;
        -u | --username)
            shift
            REGISTRY_USERNAME="$1"
            ;;
        -p | --password)
            shift
            REGISTRY_PASSWORD="$1"
            ;;
        -s | --subject)
            shift
            REGISTRY_TLS_CERT_SUBJECT="$1"
            ;;
        -r | --registry)
            shift
            REGISTRY_HOST="$1"
            ;;
        -c | --clean)
            REGISTRY_RESET=true
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        -h | --help)
            print_registry_service_init_usage
            exit 1
            ;;
        *)
            print_registry_service_init_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses arguments for 'registry service start' action
#
parse_registry_service_start_arguments() {
    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        -p | --port)
            shift
            REGISTRY_PORT="$1"
            ;;
        -d | --dir)
            shift
            REGISTRY_DIR="$1"
            ;;
        -e | --engine)
            shift
            CONTAINER_ENGINE="$1"
            ;;
        -i | --image)
            shift
            REGISTRY_IMAGE="$1"
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        -h | --help)
            print_registry_service_start_usage
            exit 1
            ;;
        *)
            print_registry_service_start_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses arguments for 'registry service stop' action
#
parse_registry_service_stop_arguments() {
    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        -e | --engine)
            shift
            CONTAINER_ENGINE="$1"
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        -h | --help)
            print_registry_service_stop_usage
            exit 1
            ;;
        *)
            print_registry_service_stop_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Prints usage menu for 'registry service' action
#
print_registry_service_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry service [init|start|stop]"
    echo ""
    echo "A helper to intialize, start and stop a docker registry"
    echo ""
    echo "Options:"
    echo "   init         Initialize a docker registry"
    echo "   start        Start a docker registry"
    echo "   stop         Stop a running docker registry"
    echo "   -h, --help   Print usage information"
    echo ""
}

#
# Prints usage menu for 'registry service init' action
#
print_registry_service_init_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry service init [-u USERNAME] [-p PASSWORD] [OPTIONS]..."
    echo ""
    echo "Configure a docker registry with self-sign certificate"
    echo ""
    echo "Options:"
    echo "   -u, --username string   Default registry user account"
    echo "   -p, --password string   Default registry user password"
    echo "   -d, --dir string        Local directory for the docker registry. Default is /tmp/docker-registry"
    echo "   -s  --subject string    Self-sign TLS certificate subject"
    echo "   -r  --registry string   IP or FQDN for the docker registry. Default is local hostname"
    echo "   -c  --clean             Clean up all existing repositories data"
    echo "   -l, --log-level string  Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   -h, --help              Print usage information"
    echo ""
}

#
# Prints usage menu for 'registry service start' action
#
print_registry_service_start_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry service start [OPTIONS]..."
    echo ""
    echo "Start a docker registry container"
    echo ""
    echo "Options:"
    echo "   -p, --port number          Image registry service port. Default is 5000"
    echo "   -d, --dir string           Local directory for the docker registry. Default is ${REGISTRY_DIR}"
    echo "   -e, --engine string        Container engine to run the container. Either 'podman' or 'docker'"
    echo "                              If not specified, it will be detected automatically"
    echo "   -i, --image string         Docker registry image. Default is ${REGISTRY_IMAGE}"
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   -h, --help                 Print usage information"
    echo ""
}

#
# Prints usage menu for 'registry service stop' action
#
print_registry_service_stop_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry service stop [OPTIONS]..."
    echo ""
    echo "Stop a running docker registry container"
    echo ""
    echo "Options:"
    echo "   -e, --engine string        Container engine used to start the container. Either 'podman' or 'docker'."
    echo "                              If not specified, it will be detected automatically"
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   -h, --help                 Print usage information"
    echo ""
}

#
# Validates arguments for 'registry service init' action
#
validate_registry_service_init_arguments() {
    if [[ "$REGISTRY_HOST" == *':'* ]]; then
        log_error "The --registry parameter shouldn't contain port in the initialization stage. Port should be specified while starting the registry."
        exit 1
    fi

    if [ -z "${REGISTRY_DIR}" ]; then
        log_error "Registry directory not specified"
        exit 1
    fi

    if [ -z "${REGISTRY_USERNAME}" ]; then
        REGISTRY_USERNAME=admin
    fi

    if [ -z "${REGISTRY_PASSWORD}" ]; then
        REGISTRY_PASSWORD=$(openssl rand -hex 16)
        REGISTRY_PASSWORD_GENERATED=true
    fi

    if [ -z "${REGISTRY_TLS_CERT_SUBJECT}" ]; then
        log_error "Registry TLS certificate subject not specified"
        exit 1
    fi
}

#
# Validates arguments for 'registry service start' action
#
validate_registry_service_start_arguments() {
    if [ ! -d "${REGISTRY_DIR}" ]; then
        log_error "Registry directory not found: ${REGISTRY_DIR}"
        exit 1
    fi

    if [ ! -d "${REGISTRY_DIR}/data" ]; then
        log_error "Registry data directory not found: ${REGISTRY_DIR}/data"
        exit 1
    fi

    if [ ! -f "${REGISTRY_DIR}/certs/server.crt" ]; then
        log_error "Missing registry TLS certificate: ${REGISTRY_DIR}/certs/server.crt"
        exit 1
    fi

    if [ ! -f "${REGISTRY_DIR}/certs/server.key" ]; then
        log_error "Missing registry TLS private key: ${REGISTRY_DIR}/certs/server.key"
        exit 1
    fi

    if [ ! -f "${REGISTRY_DIR}/hostname" ]; then
        REGISTRY_SERVER=$(cat "${REGISTRY_DIR}/hostname}")
    fi

    if [ ! -z "${CONTAINER_ENGINE}" ]; then
        if [ "${CONTAINER_ENGINE}" != "podman" ] && [ "${CONTAINER_ENGINE}" != "docker" ]; then
            log_error "Unsupported container engine specified: ${CONTAINER_ENGINE}"
            exit 1
        fi
    fi
}

#
# Validates arguments for 'registry service stop' action
#
validate_registry_service_stop_arguments() {
    if [ ! -z "${CONTAINER_ENGINE}" ]; then
        if [ "${CONTAINER_ENGINE}" != "podman" ] && [ "${CONTAINER_ENGINE}" != "docker" ]; then
            log_error "Unsupported container engine specified: ${CONTAINER_ENGINE}"
            exit 1
        fi
    fi
}

#
# Validates required tools for 'registry service init'
#
validate_registry_service_init_required_tools() {
    # validate required tools - htpasswd
    htpasswd_command=$(command -v htpasswd 2> /dev/null)
    if [ -z "${htpasswd_command}" ];
    then
        log_error "htpasswd not found. For RHEL, use 'sudo yum install httpd-tools' to install"
        exit 1
    fi

    # validate required tools - htpasswd
    openssl_command=$(command -v openssl 2> /dev/null)
    if [ -z "${openssl_command}" ];
    then
        log_error "openssl not found. For RHEL, use 'sudo re' to install"
        exit 1
    fi
}

# ---------- Registry secret functions ----------

#
# Handles creating registry authentication secret
#
do_registry_secret_create() {
    # parses arguments
    parse_registry_secret_create_arguments "$@"

    # validates arguments
    validate_registry_secret_create_arguments

    if [ ! -z "${DRY_RUN}" ]; then
        # creates output file for dry run commands
        dry_run_registry_secret_create
    else
        run_registry_secret_create
    fi
}

#
# do_registry_secret_create in dry-run mode - Logs commands to file
#
dry_run_registry_secret_create() {
    configure_dry_run_output "1-configure-creds-airgap" "create"
    commands=()
    registry_secret_file=${AUTH_DATA_PATH}/secrets/${AUTH_REGISTRY_SERVER}.json
    commands+=("# creating registry secret for ${AUTH_REGISTRY_SERVER} and saving to file ${registry_secret_file}")
    print_dry_run_commands "${commands[@]}"
}

run_registry_secret_create() {
    # creates auth data path
    if [ ! -d "${AUTH_DATA_PATH}" ] || [ ! -d "${AUTH_DATA_PATH}/secrets" ]; then
        mkdir -p "${AUTH_DATA_PATH}/secrets"
    fi

    # creates docker auth secret
    log_info "Creating registry authentication secret for ${AUTH_REGISTRY_SERVER}"
    registry_secret_file=${AUTH_DATA_PATH}/secrets/${AUTH_REGISTRY_SERVER}.json
    registry_secret=$(echo -n "${AUTH_REGISTRY_USERNAME}:${AUTH_REGISTRY_PASSWORD}" | base64 | tr -d "\n")
    
    echo -n "{\"auths\":{\"${AUTH_REGISTRY_SERVER}\":{\"email\":\"${AUTH_REGISTRY_EMAIL}\",\"auth\":\"${registry_secret}\"}}}" > "${registry_secret_file}"
    chmod 600 "${registry_secret_file}"

    log_info "Registry secret created in ${registry_secret_file}"
    
    log_info "Created registry authentication secret for ${AUTH_REGISTRY_SERVER} in ${registry_secret_file}"
}

#
# Handles deleting registry authentication secret
#
do_registry_secret_delete() {
    # parses arguments
    parse_registry_secret_delete_arguments "$@"

    # validates arguments
    validate_registry_secret_delete_arguments

    if [ ! -z "${DRY_RUN}" ]; then
        # creates output file for dry run commands
        dry_run_registry_secret_delete
    else
        run_registry_secret_delete
    fi
}

dry_run_registry_secret_delete() {
    configure_dry_run_output "1-configure-creds-airgap" "delete"
    commnds=()
    commands+=("# checking if registry authentications exist")
    if [ -f "${AUTH_DATA_PATH}/secrets/${AUTH_REGISTRY_SERVER}.json" ]; then
        commands+=("#|-- ${AUTH_DATA_PATH}/secrets/${AUTH_REGISTRY_SERVER}.json")
        commands+=("# Deleting authentication secret for ${AUTH_REGISTRY_SERVER}")
        commands+=("rm -f \"${AUTH_DATA_PATH}/secrets/${AUTH_REGISTRY_SERVER}.json\"")
    else
        commands+=("# Registry authentication for ${AUTH_REGISTRY_SERVER} not found")
    fi
    print_dry_run_commands "${commands[@]}"
}

run_registry_secret_delete() {
    # checks if auth secret exists
    if [ -f "${AUTH_DATA_PATH}/secrets/${AUTH_REGISTRY_SERVER}.json" ]; then
        log_info "Deleting authentication secret for ${AUTH_REGISTRY_SERVER}"
        rm -f "${AUTH_DATA_PATH}/secrets/${AUTH_REGISTRY_SERVER}.json" 

        if [[ "$?" -eq 0 ]]; then
            log_info "Deleted authentication secret for ${AUTH_REGISTRY_SERVER}"
        else
            exit 11
        fi
    else
        log_error "Registry authentication for ${AUTH_REGISTRY_SERVER} not found"
        exit 1
    fi
}

#
# Handles listing registry authentication secrets
#
do_registry_secret_list() {
    # parses arguments
    parse_registry_secret_list_arguments "$@"

    if [ ! -z "${DRY_RUN}" ]; then
        # creates output file for dry run commands
        dry_run_registry_secret_list
    else
        run_registry_secret_list
    fi
}

dry_run_registry_secret_list() {
    configure_dry_run_output "1-configure-creds-airgap" "list"
    commands=()
    commands+=("# checking if registry authentications exist")
    commands+=("find \"${AUTH_DATA_PATH}/secrets\" -name \"*.json\"")
    commands+=("# listing registry for each secret")
    commands+=("#|-- ${AUTH_DATA_PATH}/secrets")
    secrets=
    if [ -d "${AUTH_DATA_PATH}/secrets" ]; then
        secrets=$(find "${AUTH_DATA_PATH}/secrets" -name "*.json")
    fi
    if [ ! -z "${secrets}" ]; then
        for secret in ${secrets}; do
            registry=$(echo "${secret}" | sed -e "s/.*\///" | sed -e "s/.json$//")
            commands+=("   ${registry}")
        done
    else
        commands+=("No registry secret found")
    fi
    print_dry_run_commands "${commands[@]}"
}

run_registry_secret_list() {
    secrets=
    if [ -d "${AUTH_DATA_PATH}/secrets" ]; then
        secrets=$(find "${AUTH_DATA_PATH}/secrets" -name "*.json")
    fi

    if [ ! -z "${secrets}" ]; then
        for secret in ${secrets}; do
            registry=$(echo "${secret}" | sed -e "s/.*\///" | sed -e "s/.json$//")
            echo "${registry}"
        done
    else
        log_info "No registry secret found"
    fi
}

#
# Handles deleting all registry authentication secrets
#
do_registry_secret_delete_all() {
    # parses arguments
    parse_registry_secret_delete_all_arguments "$@"

    if [ ! -z "${DRY_RUN}" ]; then
        dry_run_registry_secret_delete_all
    else 
        run_registry_secret_delete_all
    fi
}

dry_run_registry_secret_delete_all() {
    # creates output file for dry run commands
    configure_dry_run_output "1-configure-creds-airgap" "delete-all"
    commands=()
    commands+=("# checking if registry authentications exist")
    if [ -d "${AUTH_DATA_PATH}" ]; then
        commands+=("# deleting data path")
        commands+=("#|-- ${AUTH_DATA_PATH}")
        commands+=("rm -rf ${AUTH_DATA_PATH}")
    else 
        commands+=("# registry authentications not found - nothing to do")
    fi
    print_dry_run_commands "${commands[@]}"
}

run_registry_secret_delete_all() {
    if [ -d "${AUTH_DATA_PATH}" ]; then
        log_info "Deleting all registry authentications"
        rm -rf "${AUTH_DATA_PATH}"

        if [[ "$?" -eq 0 ]]; then
            log_info "Deleted all registry authentications"
        else
            exit 11
        fi
    else
        log_error "Registry authentications not found"
        exit 1
    fi
}

#
# Parses arguments for 'registry secret' action
#
parse_registry_secret_arguments() {
    if [[ "$#" == 0 ]]; then
        print_registry_secret_usage
        exit 1
    fi
    
    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        -c | --create)
            shift
            do_registry_secret_create "$@"
            break
            ;;
        -d | --delete)
            shift
            do_registry_secret_delete "$@"
            break
            ;;
        -l | --list)
            do_registry_secret_list "$@"
            break
            ;;
        -D | --delete-all)
            shift
            do_registry_secret_delete_all "$@"
            break
            ;;
        -h | --help)
            print_registry_secret_usage
            exit 1
            ;;
        *)
            print_registry_secret_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses arguments for 'secret create' action
#
parse_registry_secret_create_arguments() {
    if [[ "$#" == 0 ]]; then
        print_registry_secret_create_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        -u | --username)
            shift
            AUTH_REGISTRY_USERNAME="$1"
            ;;
        -p | --password)
            shift
            AUTH_REGISTRY_PASSWORD="$1"
            ;;
        -e | --email)
            shift
            AUTH_REGISTRY_EMAIL="$1"
            ;;  
        --dry-run)
            DRY_RUN=true
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;          
        -h | --help)
            print_registry_secret_create_usage
            exit 1
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        *)
            AUTH_REGISTRY_SERVER="$1"
            ;;
        esac
        shift
    done
}

#
# Parses arguments for 'registry-secret delete' action
#
parse_registry_secret_delete_arguments() {
    if [[ "$#" == 0 ]]; then
        print_registry_secret_delete_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;       
        --dry-run)
            DRY_RUN=true
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;         
        -h | --help)
            print_registry_secret_delete_usage
            exit 1
            ;;
        *)
            AUTH_REGISTRY_SERVER="$1"
            ;;
        esac
        shift
    done
}

#
# Parses arguments for 'registry-secret list' action
#
parse_registry_secret_list_arguments() {
    # if [[ "$#" == 0 ]]; then
    #     print_registry_secret_list_usage
    #     exit 1
    # fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in 
        --dry-run)
            DRY_RUN=true
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;        
        -h | --help)
            print_registry_secret_list_usage
            exit 1
            ;;
        *)
        esac
        shift
    done
}

#
# Parses arguments for 'registry-secret delete-all' action
#
parse_registry_secret_delete_all_arguments() {
    # if [[ "$#" == 0 ]]; then
    #     print_registry_secret_list_usage
    #     exit 1
    # fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in 
        --dry-run)
            DRY_RUN=true
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;        
        -h | --help)
            print_registry_secret_delete_all_usage
            exit 1
            ;;
        *)
        esac
        shift
    done
}

#
# Prints usage menu for 'registry secret' action
#
print_registry_secret_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry secret [OPTION]..."
    echo ""
    echo "Manage the authentication secrets of all the registries used in image mirroring"
    echo ""
    echo "Options:"
    echo "  -c, --create       Create an authentication secret"
    echo "  -d, --delete       Delete an authentication secret"
    echo "  -l, --list         List all authentication secrets"
    echo "  -D, --delete-all   Delete all authentication secrets"
    echo "  -h, --help         Print usage information"
    echo ""
}

#
# Prints usage menu for 'registry secret --create' action
#
print_registry_secret_create_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry secret --create -u USERNAME -p PASSWORD [-e EMAIL] REGISTRY_SERVER"
    echo ""
    echo "Creates a registry authentication secret"
    echo "REGISTRY_SERVER address should match the specific definition of an IP or FQDN which do not include a protocol."
    echo ""
    echo "Options:"
    echo "   -u, --username string      Account username"
    echo "   -p, --password string      Account password"
    echo "   -e, --email string         Account email (optional)"
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   --dry-run               Print the actions that would be taken with their results"
    echo "   --dry-run-output string If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help              Print usage information"
    echo ""
}

#
# Prints usage menu for 'registry secret --delete' action
#
print_registry_secret_delete_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry secret --delete REGISTRY_SERVER"
    echo ""
    echo "Delete a registry authentication secret"
    echo ""
    echo "Options:"
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   --dry-run               Print the actions that would be taken with their results"
    echo "   --dry-run-output string If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help              Print usage information"
    echo ""
}

#
# Prints usage menu for 'registry secret --list' action
#
print_registry_secret_list_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry secret --list"
    echo ""
    echo "List all registry authentication secrets"
    echo ""
    echo "Options:"
    echo "   --dry-run               Print the actions that would be taken with their results"
    echo "   --dry-run-output string If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help              Print usage information"
    echo ""
}

#
# Prints usage menu for 'registry secret --delete-all' action
#
print_registry_secret_delete_all_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} registry secret --delete-all "
    echo ""
    echo "Delete all registry authentication secrets"
    echo ""
    echo "Options:"
    echo "   --dry-run               Print the actions that would be taken with their results"
    echo "   --dry-run-output string If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help              Print usage information"
    echo ""
}

#
# Creates dry run output directory and commands file
#
configure_dry_run_output() {
        dry_run_output_text="All dry run commands will be printed."
        if [ -z "${DRY_RUN_OUTPUT}" ]; then
            log_info "[DRY RUN] ${dry_run_output_text}"
        else
            dir_name="${DRY_RUN_OUTPUT}/$1/$2"
            if [ ! -d ${dir_name}/ ]; then 
                mkdir -p "${dir_name}"
            fi
            echo "# ${dry_run_output_text}" > "${dir_name}/commands.txt"
        fi
}

#
# Validates arguments for 'registry-secret create' action
#
validate_registry_secret_create_arguments() {
    if [[ "$AUTH_REGISTRY_SERVER" == *'://'* ]]; then
        log_error "The registry server address should match the specific definition of an IP or FQDN which do not include a protocol."
        exit 1
    fi

    if [ -z "${AUTH_REGISTRY_USERNAME}" ]; then
        log_error "Account username not specified"
        exit 1
    fi

    if [ -z "${AUTH_REGISTRY_PASSWORD}" ]; then
        log_error "Account password not specified"
        exit 1
    fi

    if [ -z "${AUTH_REGISTRY_EMAIL}" ]; then
        AUTH_REGISTRY_EMAIL="unused"
    fi
}

#
# Validates arguments for 'registry-secret delete' action
#
validate_registry_secret_delete_arguments() {
    if [ -z "${AUTH_REGISTRY_SERVER}" ]; then
        log_error "Registry server not specified"
        exit 1
    fi
}

#
# Checking skopeo version and setting retry string if support
# RETRY is supported for subcommand in and above 1.2.0 version
#
check_skopeo_version_retry_count(){
        
    sk_ver=$([[ (($(skopeo --version | awk '{print $3}') > 1.1.9)) ]]; echo $?)

    if [ "$sk_ver" -eq 0 ]; then
        SK_RETRY_STRING="--retry-times ${SKOPEO_RETRY_COUNT}"
    fi
}


#
# Checking skopeo supports preserve-digest by looking at the help
#
check_skopeo_preserve_digest_support(){

    preserve_digest="--preserve-digests"
    if skopeo copy --help | grep -- $preserve_digest; then  
        SK_PRESERVE_DIGEST_STRING=$preserve_digest
    fi
}

# ---------- Image mirror functions ----------

#
# Handles 'image mirror' action
#
do_image_mirror() {
    # parses arguments
    parse_image_mirror_arguments "$@"
    
    # validates arguments
    validate_image_mirror_arguments

    # check skopeo retry support or not
    check_skopeo_version_retry_count


    # check skopeo support for preserve-digest
    check_skopeo_preserve_digest_support

    # if dry-run-output is set, removes old files in the given directory
    if [[ ! -z "${DRY_RUN}" ]] && [[ ! -z "${DRY_RUN_OUTPUT}" ]]; then
        rm -rf "${DRY_RUN_OUTPUT}/2-mirror-images/${TARGET_REGISTRY}"
    fi

    # set debug logging flag
    adjust_debug_logging_flag

    # sed configuration
    # A space character is needed for -i argument in mac BSD sed.
    # GNU sed has a --version argument, and BSD sed does not. 
    # Check for both conditions to be safe for darwin users that override sed with gsed
    if [ -z "${OSTYPE##*"darwin"*}" ] && ! sed --version >/dev/null 2>&1; then
        SP=" "
    fi

    # verifies if target registry is SSL enabeld
    status_code=$(curl -I -k https://${TARGET_REGISTRY} -w "%{http_code}\n" --silent --connect-timeout 5 --output /dev/null)
     if [[ ! " ${HTTPS_SUCCESS_CODE[*]} " =~ " ${status_code} " ]]; then
        REGISTRY_TLS_ENABLED=false
     fi    
    if [[ "${SHOW_REGISTRIES}" == "true" || "${SHOW_REGISTRIES_NAMESPACES}" == "true" ]]; then
        do_image_mirror_show_registries
    else

        # mirror images
        if [ ! -z "${IMAGE}" ]; then
            generate_auth_json
            if [ ! -z "${DRY_RUN}" ]; then
                do_record_single_image
            elif [ ! -z "${USE_SKOPEO}" ]; then
                do_skopeo_copy_single_image
            else
                do_image_mirror_single_image
            fi
        elif [ ! -z "${IMAGE_CSV_FILE}" ]; then
            process_case_csv_file "${IMAGE_CSV_FILE}"
            check_filter
            generate_image_mapping_file
            generate_auth_json
            if [ ! -z "${DRY_RUN}" ]; then
                do_record_case_images
            elif [ ! -z "${USE_SKOPEO}" ]; then
                do_skopeo_copy_case_images
            else
                do_image_mirror_case_images
            fi
            tag_latest_olm_catalog_images
        elif [ ! -z $CASE_ARCHIVE_DIR ]; then
            process_case_archive_dir
            generate_image_mapping_file
            generate_auth_json
            if [ ! -z "${DRY_RUN}" ]; then
                do_record_case_images
            elif [ ! -z "${USE_SKOPEO}" ]; then
                do_skopeo_copy_case_images
            else
                do_image_mirror_case_images
            fi
            tag_latest_olm_catalog_images
        fi
    fi

    if [[ ! -z "${DRY_RUN}" ]]; then
        # If DRY RUN is set, deletes all the mirrored csv created during this mirroring attempt
        cleanup_mirrored_csv_files_from_current_run
    fi
    copy_image_from_temp_to_offline
}
#
# Copy Image from temp registry to target offline registry folder
#

copy_image_from_temp_to_offline() {
    log_debug "Copying mirrored images csv file in registry directory ...."
    # Remove the :port from the input registry
    formated_registry="$(echo ${TARGET_REGISTRY} | cut -d ':' -f 1)"
    local registry_dir="${CASE_ARCHIVE_DIR}/${formated_registry}"
    if [ ! -d ${registry_dir} ]; then 
        mkdir -p "${registry_dir}"
    fi
    for csv_file in $(find ${OC_TMP_CSV_REG_DIR} -name '*-images.csv'); do
          copy_image_csv_file "${csv_file}" "${registry_dir}"
    done
    #Remove temp registry folder after copy to offline registry directory
    rm -rf ${OC_TMP_CSV_REG_DIR}
}

#
# Logs to file what would be mirrored - dry-run of do_image_mirror_single_image
#
do_record_single_image() {
    image_identifier=$(echo "${IMAGE}" | sed -e "s/[^/]*\///") # removes registry host
    image_identifier=$(echo "${image_identifier}" | sed -e "s/\@.*//") # removes image digest
    image_identifier=$(update_image_namespace "${image_identifier}") # updates namespace

    # replace the original registry with the specified source registry
    if [  ! -z "${SOURCE_REGISTRY}" ]; then
        IMAGE=$(echo "${IMAGE}" | sed -e "s/[^\/]*/${SOURCE_REGISTRY}/")
    fi

    if [ -z "${DRY_RUN_OUTPUT}" ]; then
        log_info "[DRY RUN] Printing mirroring information"
        echo "${IMAGE}=${TARGET_REGISTRY}/${image_identifier}"
    else
        log_info "[DRY RUN] Saving mirroring information to $dir_name"
        echo "${IMAGE}=${TARGET_REGISTRY}/${image_identifier}" > "${dir_name}/mapping.txt"
    fi

    if [ ! -z "${USE_SKOPEO}" ]; then
        oc_cmd="skopeo copy ${SK_RETRY_STRING} ${SK_PRESERVE_DIGEST_STRING} --all --authfile \"${AUTH_DATA_PATH}/auth.json\" --dest-tls-verify=false --src-tls-verify=false \"docker://${IMAGE}\" \"docker://${TARGET_REGISTRY}/${image_identifier}\""
    else
        oc_cmd="oc image mirror -a \"${AUTH_DATA_PATH}/auth.json\" \"${IMAGE}\" \"${TARGET_REGISTRY}/${image_identifier}\" --filter-by-os '.*' --insecure --skip-multiple-scopes"
    fi
    commands=("$oc_cmd")
    print_dry_run_commands "${commands[@]}"

    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi
}

#
# Uses `oc image mirror` command to mirror one ad-hoc image
#
do_image_mirror_single_image() {
    image_identifier=$(echo "${IMAGE}" | sed -e "s/[^/]*\///") # removes registry host
    image_identifier=$(echo "${image_identifier}" | sed -e "s/\@.*//") # removes image digest
    image_identifier=$(update_image_namespace "${image_identifier}") # updates namespace

    # replace the original registry with the specified source registry
    if [  ! -z "${SOURCE_REGISTRY}" ]; then
        IMAGE=$(echo "${IMAGE}" | sed -e "s|[^\/]*|${SOURCE_REGISTRY}|")
    fi

    log_info "Start mirroring image ..."
    oc_cmd="oc image mirror -a \"${AUTH_DATA_PATH}/auth.json\" \"${IMAGE}\" \"${TARGET_REGISTRY}/${image_identifier}\" --filter-by-os '.*' --insecure --skip-multiple-scopes ${OC_DEBUG_LOGGING}"
    log_debug "Running: ${oc_cmd}"
    eval ${oc_cmd}

    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi
}

#
# Uses `skopeo copy` command to mirror one ad-hoc image
#
do_skopeo_copy_single_image() {
    image_identifier=$(echo "${IMAGE}" | sed -e "s/[^/]*\///") # removes registry host
    image_identifier=$(echo "${image_identifier}" | sed -e "s/\@.*//") # removes image digest
    image_identifier=$(update_image_namespace "${image_identifier}") # updates namespace

    # replace the original registry with the specified source registry
    if [  ! -z "${SOURCE_REGISTRY}" ]; then
        IMAGE=$(echo "${IMAGE}" | sed -e "s|[^\/]*|${SOURCE_REGISTRY}|")
    fi
    
    log_info "Start copying image ..."
    oc_cmd="skopeo copy ${SK_RETRY_STRING} ${SK_PRESERVE_DIGEST_STRING} --all --authfile \"${AUTH_DATA_PATH}/auth.json\" --dest-tls-verify=false --src-tls-verify=false \"docker://${IMAGE}\" \"docker://${TARGET_REGISTRY}/${image_identifier}\" ${SKOPEO_DEBUG_LOGGING}"
    log_debug "Running: ${oc_cmd}"
    eval ${oc_cmd}

    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi
}

#
# Logs to file what would be mirrored - dry-run of do_image_mirror_case_images
# 
do_record_case_images() {
    if [ ! -f "${OC_TMP_IMAGE_MAP}" ]; then
        log_error "No image mapping found"
        exit 11
    fi

    # replace the original registry with the specified source registry
    if [  ! -z "${SOURCE_REGISTRY}" ]; then
        sed -i"${SP}"'' "s|[^\/]*|${SOURCE_REGISTRY}|" "${OC_TMP_IMAGE_MAP}"
    fi

    log_info "Start mirroring CASE images ..."

    # Find a number of images to mirror and exit cleanly if no images are found
    find_images_to_mirror

    map_files="${OC_TMP_IMAGE_MAP}"
    if [[ "${OC_TMP_IMAGE_MAP_SPLIT_SIZE}" -gt 0 ]] && [[ ${images_count} -gt ${OC_TMP_IMAGE_MAP_SPLIT_SIZE} ]]; then
        # splitting the image map into multiple files
        mkdir -p "${OC_TMP_IMAGE_MAP}_splits"
        split -l ${OC_TMP_IMAGE_MAP_SPLIT_SIZE} ${OC_TMP_IMAGE_MAP} ${OC_TMP_IMAGE_MAP}_splits/image_map_
        map_files=$(find "${OC_TMP_IMAGE_MAP}_splits" -name "image_map_*")
    fi

    if [ -z "${DRY_RUN_OUTPUT}" ]; then
        commands=()
        log_info "[DRY RUN] Printing mirroring information"
        for map_file in ${map_files}; do
            cat ${map_file}
            commands+=("oc image mirror -a \"${AUTH_DATA_PATH}/auth.json\" -f \"${map_file}\" --filter-by-os '.*' --insecure --skip-multiple-scopes")
            if [[ "$?" -ne 0 ]]; then
                # On error we need to clean up our mirrored csv file
                cleanup_mirrored_csv_files_from_current_run
                exit 11
            fi
        done
    else
        dir_name="${DRY_RUN_OUTPUT}/2-mirror-images/${TARGET_REGISTRY}"
        if [ ! -d ${dir_name}/ ]; then 
            mkdir -p "${dir_name}"
        fi
        commands=("# Mirroring commands that would be executed:")
        log_info "[DRY RUN] Saving mirroring information to $dir_name"
        for map_file in ${map_files}; do
            log_info "Mirroring ${map_file}"
            mapping_filename=$(basename ${map_file} | sed 's/image_map_/mapping_/' | sed "s/${OC_TMP_PREFIX}_image_mapping_.*/mapping/")
            cat ${map_file} > "$dir_name/$mapping_filename.txt"
            commands+=("oc image mirror -a \"${AUTH_DATA_PATH}/auth.json\" -f \"${dir_name}/${mapping_filename}.txt\" --filter-by-os '.*' --insecure --skip-multiple-scopes")
            if [[ "$?" -ne 0 ]]; then
                # On error we need to clean up our mirrored csv file
                cleanup_mirrored_csv_files_from_current_run
                exit 11
            fi
        done
    fi
    if [ ! -z "${USE_SKOPEO}" ]; then
        if [ -z "${DRY_RUN_OUTPUT}" ]; then
            commands=()
        else
            commands=("# Mirroring commands that would be executed:")
        fi
        # change delimiter from '= to space and add transport
        cat ${OC_TMP_IMAGE_MAP} | sed -e "s/=/ docker:\/\//" 1<> "${OC_TMP_IMAGE_MAP}"
        while read in; do
            commands+=("skopeo copy ${SK_RETRY_STRING} ${SK_PRESERVE_DIGEST_STRING} --all --authfile \"${AUTH_DATA_PATH}/auth.json\" --dest-tls-verify=false --src-tls-verify=false docker://${in}")
        done < ${OC_TMP_IMAGE_MAP}
    fi
    print_dry_run_commands "${commands[@]}"
}

#
# Uses `oc image mirror` command to mirror the CASE images
# 
do_image_mirror_case_images() {
    if [ ! -f "${OC_TMP_IMAGE_MAP}" ]; then
        log_error "No image mapping found"
        exit 11
    fi

    # replace the original registry with the specified source registry
    if [  ! -z "${SOURCE_REGISTRY}" ]; then
        sed -i"${SP}"'' "s|[^\/]*|${SOURCE_REGISTRY}|" "${OC_TMP_IMAGE_MAP}"
    fi

    log_info "Start mirroring CASE images ..."

    # Find a number of images to mirror and exit cleanly if no images are found
    find_images_to_mirror

    map_files="${OC_TMP_IMAGE_MAP}"

    if [[ "${OC_TMP_IMAGE_MAP_SPLIT_SIZE}" -gt 0 ]] && [[ ${images_count} -gt ${OC_TMP_IMAGE_MAP_SPLIT_SIZE} ]]; then
        # splitting the image map into multiple files
        mkdir -p "${OC_TMP_IMAGE_MAP}_splits"
        split -l ${OC_TMP_IMAGE_MAP_SPLIT_SIZE} ${OC_TMP_IMAGE_MAP} ${OC_TMP_IMAGE_MAP}_splits/image_map_
        map_files=$(find "${OC_TMP_IMAGE_MAP}_splits" -name "image_map_*")
    fi

    for map_file in ${map_files}; do
        log_info "Mirroring ${map_file}"
        oc_cmd="oc image mirror -a \"${AUTH_DATA_PATH}/auth.json\" -f \"${map_file}\" --filter-by-os '.*' --insecure --skip-multiple-scopes ${OC_DEBUG_LOGGING}"
        log_debug "Running: ${oc_cmd}"
        eval ${oc_cmd}

        if [[ "$?" -ne 0 ]]; then
            # On error we need to clean up our mirrored csv file
            cleanup_mirrored_csv_files_from_current_run
            
            exit 11
        fi
    done
}

#
# Checks if there are any images to mirror and if not, exits cleanly
#
find_images_to_mirror() {
    images_count=$(wc -l "${OC_TMP_IMAGE_MAP}" | awk '{ print $1 }')
    log_info "Found ${images_count} images"

    # Exit cleanly if no images are found to mirror
    if [[ ${images_count} == 0 ]]; then
      for mirrored_csv in ${MIRRORED_IMAGE_CSV_CONTEXT[@]}; do
        if [[ ${mirrored_csv} == *"-delta-images-"* ]]; then
          cleanup_mirrored_csv_files_from_current_run
          log_info "Found 0 images that had not already been mirrored. No additional work to do. Use the '--skipDelta 1' argument to force images to be mirrored."
          exit 0
        fi
      done
      cleanup_mirrored_csv_files_from_current_run
     if [[ -z ${IMAGE_GROUPS} ]]; then
          log_error "Found 0 images to be mirrored. Make sure that the download directory path is correct and that any specified groups are valid."
          exit 11
      else
          filter_list=$(echo $IMAGE_GROUPS $IMAGE_ARCHS | sed "s/ /,/g")
          log_info "Found 0 images matching the specified filter: [--filter $filter_list]"
          exit 0
      fi
    fi
}

#
# Uses `skopeo copy` command to mirror the CASE images
#
do_skopeo_copy_case_images() {
    if [ ! -f "${OC_TMP_IMAGE_MAP}" ]; then
        log_error "No image mapping found"
        exit 11
    fi

    # replace the original registry with the specified source registry
    if [  ! -z "${SOURCE_REGISTRY}" ]; then
        sed -i"${SP}"'' "s|[^\/]*|${SOURCE_REGISTRY}|" "${OC_TMP_IMAGE_MAP}"
    fi
    # change delimiter from '= to space and add transport
    cat ${OC_TMP_IMAGE_MAP} | sed -e "s/=/ docker:\/\//" 1<> "${OC_TMP_IMAGE_MAP}"

    log_info "Start mirroring CASE images ..."

    # Find a number of images to mirror and exit cleanly if no images are found
    find_images_to_mirror
    while read in; do
        oc_cmd="skopeo copy ${SK_RETRY_STRING} ${SK_PRESERVE_DIGEST_STRING} --all --authfile \"${AUTH_DATA_PATH}/auth.json\" --dest-tls-verify=false --src-tls-verify=false docker://${in} ${SKOPEO_DEBUG_LOGGING}" ;

        log_debug "Running: ${oc_cmd}"
        eval ${oc_cmd}

        if [[ "$?" -ne 0 ]]; then
            # On error we need to clean up our mirrored csv file
            cleanup_mirrored_csv_files_from_current_run

            exit 11
        fi
    done < ${OC_TMP_IMAGE_MAP}
}

#
# Shows all the registries that would be used
#
do_image_mirror_show_registries() {
    # generates image mapping file
    if [ ! -z "${IMAGE}" ]; then
        process_single_image_mapping
    elif [ ! -z "${IMAGE_CSV_FILE}" ]; then
        process_case_csv_file "${IMAGE_CSV_FILE}"
        check_filter
        generate_image_mapping_file
    elif [ ! -z $CASE_ARCHIVE_DIR ]; then
        process_case_archive_dir
        generate_image_mapping_file
    fi

   if [ ! -z "${DRY_RUN}" ]; then
        local dry_run_output_text="Since --show-registries flag was provided, an actual mirroring is not happening. Instead, all the registries that would be used are printed."
        if [ -z "${DRY_RUN_OUTPUT}" ]; then
            log_info "[DRY RUN] ${dry_run_output_text}"
        else
            dir_name="${DRY_RUN_OUTPUT}/2-mirror-images/${TARGET_REGISTRY}"
            if [ ! -d ${dir_name}/ ]; then 
                mkdir -p "${dir_name}"
            fi
            echo "# ${dry_run_output_text}" >> "${dir_name}/commands.txt"
        fi
    fi
    if [ -f "${OC_TMP_IMAGE_MAP}" ]; then
        # replace the original registry with the specified source registry
        if [  ! -z "${SOURCE_REGISTRY}" ]; then
            sed -i"${SP}"'' "s|[^\/]*|${SOURCE_REGISTRY}|" "${OC_TMP_IMAGE_MAP}"
        fi

        if [[ "${SHOW_REGISTRIES}" == "true" ]]; then
            log_info "Registries that would be used in this action"
            cat "${OC_TMP_IMAGE_MAP}" | awk -F'/' '{ print $1 }' | sort -u

            if [ ! -z "${TARGET_REGISTRY}" ]; then
                echo "${TARGET_REGISTRY}"
            fi
        elif [[ "${SHOW_REGISTRIES_NAMESPACES}" == "true" ]]; then
            log_info "Registries and namespaces that would be used in this action"
            cat "${OC_TMP_IMAGE_MAP}" | awk -F'/' '{ print $1 "/" $2 }' | sort -u
        fi
    else
        log_error "No registry found"
    fi
}

#
# Validates that the OLM catalog image tag must be in the following formats:
# vX.Y[.Z]-YYYYMMDD.HHmmss[-HEXCOMMIT][-OS.ARCH[.VAR]]]
# [v]X.Y[.Z]
# YYYY-MM-DD-HHmmss[-HEXCOMMIT]
#
is_valid_olm_catalog_tag() {
    local tag=$1

    if [[ ${tag} =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?-[0-9]{8}\.[0-9]{6}(-[A-Fa-f0-9]{9})?-(linux|windows)\.(amd64|arm32|arm64|i386|mips64le|ppc64le|s390x|windows-amd64)(.v[5-8])?$ ]]; then
        # OFFICIAL tag with os-arch formats:
        # v4.5.1-20200902.220310-CE62727AE-linux.arm64.v8 or v4.5-20200902.220310-CE62727AE-linux.arm64.v8
        # v4.5.1-20200902.220310-CE62727AE-linux.amd64 or v4.5-20200902.220310-CE62727AE-linux.amd64
        # v4.5.1-20200902.220310-linux.arm64.v8 or v4.5-20200902.220310-linux.arm64.v8
        # v4.5.1-20200902.220310-linux.amd64 or v4.5-20200902.220310-linux.amd64
        echo "true"
    elif [[ ${tag} =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?-[0-9]{8}\.[0-9]{6}(-[A-Fa-f0-9]{9})?$ ]]; then
        # OFFICIAL tag without os-arch formats:
        # v4.5.1-20200902.220310-CE62727AE or v4.5-20200902.220310-CE62727AE
        # v4.5.1-20200902.220310 or v4.5-20200902.220310
        echo "true"
    elif [[ ${tag} =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
        # SEMVER tag with exact match formats: 2.0 or 2.0.1
        echo "true"
    elif [[ ${tag} =~ ^[0-9]+(\.[0-9]+){1,2}-[A-Za-z0-9] ]]; then
        # SEMVER tag with leading match formats: 2.0-beta or 2.1.0-linux.amd64
        echo "true"
    elif [[ ${tag} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}(-[A-Fa-f0-9]{9})?$ ]]; then
        # TIMESTAMP tag with exact match formats: 2020-06-25-052612-e9a7f609f or 2020-06-25-052612
        echo "true"
    elif [[ ${tag} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}(-[A-Fa-f0-9]{9})?-[A-Za-z] ]]; then
        # TIMESTAMP tag with leading match formats: 2020-06-25-052612-e9a7f609f-beta or 2020-06-25-052612-linux.amd64
        echo "true"
    elif [[ ${tag} =~ ^v?[0-9]+$ ]]; then
        # INTEGER tag with exact match formats: v1 or 1
        echo "true"
    elif [[ ${tag} =~ ^v?[0-9]+-[A-Za-z] ]]; then
        # INTEGER tag with leading match formats: v1-beta or 1-linux.amd64
        echo "true"
    else
        # no match
        echo "false"
    fi
}

#
# Returns the significant portion of a supported tag
# 
get_tag_significance() {
    local tag=$1
    local significance=

    if [[ ${tag} =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?-[0-9]{8}\.[0-9]{6}$ || ${tag} =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?-[0-9]{8}\.[0-9]{6}- ]]; then
        # OFFICIAL tag with significant portion: v4.5.1-20200902
        significance=$(echo "${tag}" | sed -e 's|^\(v[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?-[0-9]\{8\}\).*|\1|')
    elif [[ ${tag} =~ ^[0-9]+(\.[0-9]+){1,2}$ || ${tag} =~ ^[0-9]+(\.[0-9]+){1,2}-[A-Za-z] ]]; then
        # SEMVER tag significant portion: 1.2.3
        significance=$(echo "${tag}" | sed -e 's|^\([0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?\)-.*|\1|')
    elif [[ ${tag} =~ ^[0-9]+(\.[0-9]+){1,2}-[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then
        # SEMVER tag with timestamp significant portion: 1.2.3-2020-06-25
        significance=$(echo "${tag}" | sed -e 's|^\([0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?-[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)-.*|\1|')
    elif [[ ${tag} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ || ${tag} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$ || ${tag} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}-[A-Za-z0-9] ]]; then
        # TIMESTAMP tag significant portion: 2020-06-25
        significance=$(echo "${tag}" | sed -e 's|^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)-.*|\1|')
    elif [[ ${tag} =~ ^v?[0-9]+$ || ${tag} =~ ^v?[0-9]+-[A-Za-z] ]]; then
        # INTEGER tag significant portion: v1 or 1
        significance=$(echo "${tag}" | sed -e 's|^\(v\?[0-9]\+\)-.*|\1|')
    fi

    echo $significance
}

#
# Tags latest OLM catalog images
#
tag_latest_olm_catalog_images() {
    if [ ! -z "${DRY_RUN}" ]; then
        local dry_run_output_text="After the actual mirroring process the OLM catalog images would be tagged latest appropriately"
        if [ -z "${DRY_RUN_OUTPUT}" ]; then
            log_info "[DRY RUN] ${dry_run_output_text}"
        else
            dir_name="${DRY_RUN_OUTPUT}/2-mirror-images/${TARGET_REGISTRY}"
            if [ ! -d ${dir_name}/ ]; then 
                mkdir -p "${dir_name}"
            fi
            echo "# ${dry_run_output_text}" >> "${dir_name}/commands.txt"
        fi
    else
        if [ -f "${OC_TMP_IMAGE_MAP}.CATALOG" ]; then
            catalog_images=$(cat "${OC_TMP_IMAGE_MAP}.CATALOG" | grep "=olm-catalog=")

            if [[ ! -z "${catalog_images}" ]] && [[ "${REGISTRY_TLS_ENABLED}" == "true" ]]; then
                extract_ca_cert
            fi

            for catalog_image in ${catalog_images}; do
                image=$(echo "${catalog_image}" | awk -F'=' '{ print $2 }' | rev | sed -e "s|[^:]*:||" | rev)
                tag=$(echo "${catalog_image}" | awk -F'=' '{ print $2 }' | sed -e "s|.*:||")
                sha=$(echo "${catalog_image}" | awk -F'=' '{ print $1 }' | sed -e "s|.*@||")
                arch=$(echo "${catalog_image}" | awk -F'=' '{ print $4 }')
                latest_tag="latest"

                # append arch to latest_tag
                if [[ ! -z "${arch}" ]]; then
                    latest_tag="${latest_tag}-${arch}"
                fi

                # only considers tag with supported format
                if [[ "$(is_valid_olm_catalog_tag ${tag})" == "true" ]]; then
                    validate_image_mirror_required_tools
                    log_info "Retrieving image tags from ${image}"
                    skopeo_cmd="skopeo list-tags --tls-verify=false --authfile ${AUTH_DATA_PATH}/auth.json docker://${image}"
                    log_debug "Running: ${skopeo_cmd}"
                    all_tags=$(${skopeo_cmd} | tr -d "\r|\n| " | sed -e 's|.*"Tags":\[||' | sed -e 's|\].*||' | sed -e 's|"||g' | sed -e 's|,|\n|g' | grep -v '^latest' | sort -V)
                    printf "[INFO] Available tags:\n${all_tags}\n"

                    if [[ ! -z "${all_tags}" ]]; then
                        last_tag=$(printf "${all_tags}" | tail -1)
                        tag_significane=$(get_tag_significance "${tag}")

                        if [[ ${last_tag} =~ ^${tag_significane} ]]; then
                            # tags the current image as latest if the latest tag already exists 
                            # and the current image is the most recent version
                            log_info "Tagging ${image}:${tag} as ${image}:${latest_tag}"    

                            oc_cmd="oc image mirror -a \"${AUTH_DATA_PATH}/auth.json\" \"${image}@${sha}\" \"${image}:${latest_tag}\" --filter-by-os '.*' --insecure  --skip-multiple-scopes ${OC_DEBUG_LOGGING}"
                            log_debug "Running: ${oc_cmd}"
                            eval ${oc_cmd}

                            if [[ "$?" -ne 0 ]]; then
                                exit 11
                            fi
                        else
                            log_debug "Not most recent tag ${tag}, skip tagging as ${latest_tag}"
                        fi
                    fi
                fi
            done
        fi
    fi
}

#
# Generates auth.json file for 'oc image mirror'
#
generate_auth_json() {
    if [ ! -z "${DRY_RUN}" ]; then
        local dry_run_output_text="Prior to actually mirroring images, an auth.json file is constructed at ${AUTH_DATA_PATH}/auth.json from all of the secrets added by the configure-creds-airgap create"
        if [ -z "${DRY_RUN_OUTPUT}" ]; then
            log_info "[DRY RUN] ${dry_run_output_text}"
        else
            dir_name="${DRY_RUN_OUTPUT}/2-mirror-images/${TARGET_REGISTRY}"
            if [ ! -d ${dir_name}/ ]; then 
                mkdir -p "${dir_name}"
            fi
            echo "# ${dry_run_output_text}" >> "${dir_name}/commands.txt"
        fi
    else
        log_info "Generating auth.json"
        printf "{\n  \"auths\": {" > "${AUTH_DATA_PATH}/auth.json"
        chmod 600 "${AUTH_DATA_PATH}/auth.json"

        if [ -d "${AUTH_DATA_PATH}/secrets" ]; then
            all_registry_auths=
            for secret in $(find "${AUTH_DATA_PATH}/secrets" -name "*.json"); do
                registry_auth=$(cat ${secret} | sed -e "s/^{\"auths\":{//" | sed -e "s/}}$//")
                if [[ "$?" -eq 0 ]]; then
                    if [ ! -z "${all_registry_auths}" ]; then
                        printf ",\n    ${registry_auth}" >> "${AUTH_DATA_PATH}/auth.json"
                    else
                        printf "\n    ${registry_auth}" >> "${AUTH_DATA_PATH}/auth.json"
                    fi
                    all_registry_auths="${all_registry_auths},${registry_auth}"
                fi
            done
        fi

        printf "\n  }\n}\n" >> "${AUTH_DATA_PATH}/auth.json"
    fi
}

#
# Generates image mapping file
#
generate_image_mapping_file() {
    log_info "Generating image mapping file ${OC_TMP_IMAGE_MAP}"
    mtype=(IMAGE LIST)
    for type in "${mtype[@]}"; do
        if [ -f "${OC_TMP_IMAGE_MAP}.${type}" ]; then
            # sort and remove duplicates
            cat "${OC_TMP_IMAGE_MAP}.${type}" | sed -e "s|=olm-catalog=.*||g" | sort -u >> "${OC_TMP_IMAGE_MAP}"
            cat "${OC_TMP_IMAGE_MAP}.${type}" | grep -E "=olm-catalog=" | sort -u >> "${OC_TMP_IMAGE_MAP}.CATALOG"
        fi
    done
}

#
# Processes single image mapping
#
process_single_image_mapping() {
    image_identifier=$(echo "${IMAGE}" | sed -e "s/[^/]*\///") # removes registry host
    image_identifier=$(update_image_namespace "${image_identifier}") # updates registry host
    echo "${IMAGE}=${TARGET_REGISTRY}/${image_identifier}" > "${OC_TMP_IMAGE_MAP}"
}

#
# Cleanup the mirrored images CSV files from the current run when 
# oc image mirror command fails
#
cleanup_mirrored_csv_files_from_current_run() {
    log_info "Deleting mirrored image csv files created during this mirror attempt"
    for mirrored_csv in ${MIRRORED_IMAGE_CSV_CONTEXT[@]}; do
        rm -f ${mirrored_csv}
    done
}

#
# Create a mirrored image CSV file for the local disk
# File is saved in a folder in the offline cache that
# matches the name of the registry mirrored to 
#
create_mirrored_images_csv() {
    local image_csv="${1}"
    local registry="${2}"
    local time_stamp="${3}"

    # Remove the :port from the input registry
    formated_registry="$(echo ${registry} | cut -d ':' -f 1)"
    local registry_dir="${OC_TMP_CSV_REG_DIR}/${formated_registry}"

    if [ ! -d ${registry_dir} ]; then 
        mkdir -p "${registry_dir}"
    fi

    # Get just the case name and version from the image CSV file
    local image_basename="$(basename ${image_csv})"
    local mirrored_csv_name="$(echo ${image_basename} | sed -e 's|-images.csv.tmp||g')"
    if [ ${image_basename} == ${mirrored_csv_name} ]; then
    mirrored_csv_name="$(echo ${image_basename} | sed -e 's|.csv.tmp||g')"
    fi
    local mirrored_csv_file_path="${registry_dir}/${mirrored_csv_name}-mirrored-images.csv"

    copy_image_csv_file "${image_csv}" "${mirrored_csv_file_path}"

    # Add the mirrored CSV path to the global context to be used later
    MIRRORED_IMAGE_CSV_CONTEXT[${#MIRRORED_IMAGE_CSV_CONTEXT[@]}]="${mirrored_csv_file_path}"
}

#
# Copy image csv file to target folder
#

copy_image_csv_file() {
    local image_csv="${1}"
    local mirrored_csv_file_path="${2}"
        # If a file of this name already exists in the directory, then add some timestamp information to it
    if [ -f ${mirrored_csv_file_path} ]; then 
        log_info "Updating a CSV file of mirrored images at ${mirrored_csv_file_path}"

        # mirrored_csv_file_path="${registry_dir}/${mirrored_csv_name}-${time_stamp}-mirrored-images.csv"
        local lines="$(cat ${image_csv})"
        for line in ${lines[@]}; do
            rc=0
            grep "${mirrored_csv_file_path}" -e "${line}" >> /dev/null 2>&1; rc=${?}
            # Append non-unique and already existing lines to the csv file
            if [[ ${rc} -eq 1 ]]; then 
                echo "${line}" >> "${mirrored_csv_file_path}"
            fi
        done
    else
        log_info "Creating a CSV file of mirrored images at ${mirrored_csv_file_path}"
        cp "${image_csv}" "${mirrored_csv_file_path}"
    fi
}

#
# check if FILTER_FAILS is set to true
# if so, throws an error as no images were found which satisfy the given filters
#
check_filter() {
    if [[ $FILTER_FAILS == true ]]; then
        filter_list=$(echo $IMAGE_GROUPS $IMAGE_ARCHS | sed "s/ /,/g")
        echo "[INFO] Did not find any images matching the specified filter: [--filter $filter_list]. Continuing to mirror all images."
     fi
}

#
# Filters the list images by either groups or archs
#   Arguments: input_csv, output_csv, filter_value, filter_column_number
#
filter_csv_rows() {
    old_ifs=${IFS}
    IFS=","
    local image_criteria_arr=($3)
    IFS=${old_ifs}
    local images_found=false
    head -n 1 ${1} > ${2}
    # ignore commented lines (starting with #)
    local image_csv_lines=($(cat ${1} | sed '/^#/d'))
    for i in "${!image_csv_lines[@]}"; do
        if [ ${i} -eq 0 ]; then continue; fi 
        # pick the right column number for groups or archs in the CSV file (12 for groups, 7 for archs)
        local line=$(printf ${image_csv_lines[${i}]} | awk -F ',' "{ print \$${4} }")
        line=$(echo ${line} | sed -e "s|[\"']||g")
        #
        # [Group filtering]
        # If there is no value in the criteria row, or criteria columns in the CSV,
        # then default to add the row to the temp CSV file
        # [Arch filtering]
        # If no value in the criteria row, skip the row
        #
        if [[ -z ${line} ]] && [[ ${4} != 7 ]]; then
            echo "${image_csv_lines[${i}]}" >> "${2}"
        else 
            old_ifs=${IFS}
            IFS=";"
            local line_criteria_arr=($line)
            IFS=${old_ifs}
            # Check for existence of the passed in criteria in the csv row item
            for i_criteria in ${image_criteria_arr[@]}; do
                if [[ " ${line_criteria_arr[@]} " =~ " ${i_criteria} " ]]; then
                    echo "${image_csv_lines[${i}]}" >> "${2}"
                    images_found=true
                    break
                fi
            done
        fi 
    done
    echo $images_found
}

#
# Processes a CASE CSV file and output to ${OC_TMP_IMAGE_MAP} file
#
process_case_csv_file() {
    csv_file="${1}"
    local criteria_present=

    # Begin filtering the images based on input groups
    local readonly base_csv="$(basename ${csv_file})"
    local tmp_csv_file="${OC_TMP_CSV_DIR}/${base_csv}"
    if [ ! -d $(dirname ${tmp_csv_file}) ]; then mkdir -p $(dirname ${tmp_csv_file}); fi
    if [ -f "${tmp_csv_file}" ]; then rm -f "${tmp_csv_file}"; fi
    
    log_info "Copying image CSV file at ${csv_file} to ${tmp_csv_file} temporarily"

    # Prepare tmp csv file for mirroring everything or for further filtering by arch 
    if [[ -z ${IMAGE_GROUPS} ]]; then
        # Do not copy comments (lines starting with #) into tmp_csv_file
        sed '/^#/d' < "${csv_file}" > "${tmp_csv_file}"
    else
        # Filter images from the CSV file based on input groups
        criteria_present=$(filter_csv_rows "${csv_file}" "${tmp_csv_file}" "${IMAGE_GROUPS}" "12")
    fi

    # Determine if further filtering is needed (by arch)
    if [[ ! -z ${IMAGE_ARCHS} ]]; then
        local tmp_arch_csv_file="${OC_TMP_CSV_DIR}/arch_${base_csv}"
        # Filter images from the CSV file based on input archs
        criteria_present=$(filter_csv_rows "${tmp_csv_file}" "${tmp_arch_csv_file}" "${IMAGE_ARCHS}" "7")
        cp "${tmp_arch_csv_file}" "${tmp_csv_file}"
    fi

    # checks if filter is failing
    # if no images from this csv satisfy the criteria and no previous images from other csv satisfied the criteria
    # set the FILTER_FAILS variable to true
    # if images from this csv satisfy the criteria, set the variable to false
    if [[ ! -z $criteria_present ]]; then
        if [[ "$criteria_present" == true ]]; then
            FILTER_FAILS=false
        elif [[ -z $FILTER_FAILS ]]; then
            FILTER_FAILS=true
        fi
    fi

    default_tag=$(date "+%Y%m%d%M%S")

    # Since the tmp_csv_file feeds the generation of the oc image mirror mapping
    # then use this as the file to save as the content that was mirrored in this run
    #
    # Only create the mirrored images csv file when the mirror action is called
    if [[ ! -z ${IMAGE_MIRROR_ACTION_CALLED} ]] && [[ $(wc -c < "${tmp_csv_file}") -gt 0 ]]; then 
        create_mirrored_images_csv "${tmp_csv_file}" "${TARGET_REGISTRY}" "${default_tag}"
    fi

    log_info "Processing image CSV file at ${tmp_csv_file}"
    
    # process FAT and LIST images, and print $registry/$image_name:$digest=$target_registry/$image_name:$tag
    mtype=(IMAGE LIST)
    for type in "${mtype[@]}"; do
        cat "${tmp_csv_file}" | sed -e "s|[\"']||g" | grep ",${type}," \
        | awk -v target_registry=${TARGET_REGISTRY} -v default_tag=${default_tag} \
            -v ns_action=${NAMESPACE_ACTION} -v ns_value=${NAMESPACE_ACTION_VALUE} -F',' \
        '{ printf $1 "/" $2 "@" $4 "=" target_registry "/" } \
        { split($2, paths, "/"); sub(paths[1], "", $2);
          if (ns_action == "replace") { printf ns_value } \
          else if (ns_action == "prefix") { printf ns_value paths[1] } \
          else if (ns_action == "suffix") { printf paths[1] ns_value } \
          else { printf paths[1] } \
          printf $2
        } \
        { printf ":" ($3 == "" ? default_tag ( $6 != "" ? "-" $6 : "") ( $7 != "" ? "-" $7 : "") : $3) \
        } \
        { print ($11 == "olm-catalog" ? ( "=" $11 "=" $7 ) : "") }' \
        >> "${OC_TMP_IMAGE_MAP}.${type}"
    done

    log_info "Removing temp ${tmp_csv_file} images.csv file"
    rm -f "${tmp_csv_file}"
}

#
# Process all the CASE images CSV files found in the CASE archive directory
#
process_case_archive_dir() {
    log_info "Processing CASE archive directory: ${CASE_ARCHIVE_DIR}"
    # If there is a delta CSV file and SKIP_DELTA is not set, then use the latest delta CSV in the registries dir
    delta_csv=
    # Remove the :port from the input registry
    formated_registry="$(echo ${TARGET_REGISTRY} | cut -d ':' -f 1)"
    local registry_dir="${CASE_ARCHIVE_DIR}/${formated_registry}"

    # If the registry directory already exists, SKIP_DELTA is not set, and there is a CASE archive specified, then create the image delta
    if [ -z ${SKIP_DELTA} ]; then
      if [ -d ${registry_dir} ] && [ ! -z ${CASE_ARCHIVE} ]; then
        log_info "Attempting to create delta list of images"
        cloudctl case create-images-delta --case ${CASE_ARCHIVE_DIR}/${CASE_ARCHIVE} --registry ${formated_registry} > /dev/null 2>&1
        if [ $? == 0 ]; then
          log_info "Create delta images list successful"
        else
          log_info "Create delta images list unsuccessful. Full list of images will be mirrored."
        fi
      fi

      # Find the newest delta images file, if there is one
      my_array=($(ls ${registry_dir}/*-delta-images-*.csv 2> /dev/null | grep -v \\-mirrored-images.csv | awk '{ split($0,a,/-delta-images-/); print a[2] }' | sort -r))

      if [ ${#my_array[@]} -ne 0 ]; then
        delta_csv=`ls ${registry_dir}/*${my_array[0]}`
      fi
    fi

    # If we did not find a delta images CSV, then process all existing CSVs, otherwise only process the delta CSV
    if [ -z ${delta_csv} ]; then
      for csv_file in $(find ${CASE_ARCHIVE_DIR} -name '*-images.csv'); do
        # Exclude -mirrored csv files from the list to mirror
        if [[ ! "${csv_file}" == *"-mirrored-images.csv"* ]]; then
          process_case_csv_file "${csv_file}"
        fi
      done
      check_filter
    else
      csv_base="$(basename ${delta_csv})"
      cp ${registry_dir}/$csv_base ${CASE_ARCHIVE_DIR}
      process_case_csv_file "${CASE_ARCHIVE_DIR}/${csv_base}"
      rm ${CASE_ARCHIVE_DIR}/${csv_base}
      check_filter
    fi
}

#
# Prints usage menu for 'image mirror' action
#
print_image_mirror_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} image mirror [--dry-run|--dry-run-output DIR_NAME]"
    echo "       [--show-registries|--show-registries-namespaces]"
    echo "       [--image IMAGE|--csv IMAGE_CSV_FILE|--dir CASE_ARCHIVE_DIR]"
    echo "       [--ns-replace NAMESPACE|--ns-prefix PREFIX|--ns-suffix SUFFIX]"
    echo "       [--from-registry SOURCE_REGISTRY] --to-registry TARGET_REGISTRY"
    echo "       [--split-size SPLIT_SIZE]"
    echo "       [--log-level LOG_LEVEL]"
    echo ""
    echo "Mirror CASE images to an image registry to prepare for Air-Gapped installation"
    echo ""   
    echo "Options:"
    echo "   --dry-run                      Print the actions that would be taken together with their results"   
    echo "   --dry-run-output string        If specified, the output of dry run will be saved to given directory"   
    echo "   --show-registries              Print the registries that would be used"
    echo "   --show-registries-namespaces   Print the registries and namespaces that would be used"
    echo "   --image string                 Image to mirror"
    echo "   --csv string                   CASE images CSV file"
    echo "   --dir string                   CASE archive directory that contains the image CSV files"
    echo "   --ns-replace string            Replace the namespace of the mirror image"
    echo "   --ns-prefix string             Append a prefix to the namespace of the mirror image"
    echo "   --ns-suffix string             Append a suffix to the namespace of the mirror image"
    echo "   --from-registry string         Mirror the images from a private registry"
    echo "   --to-registry string           Mirror the images to another private registry"
    echo "   --split-size int               Mirror the images in batches with a given split size. Default is 100"
    echo "   -l, --log-level string         Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   -h, --help                     Print usage information"
    echo ""
    echo "Example 1: Mirror all CASE images to a private registry"
    echo "${script_name} image mirror --dry-run --dir ./offline --to-registry registry1.example.com:5000"
    echo ""
    echo "Example 2: Mirror all CASE images from a private registry to a another private registry"
    echo "${script_name} image mirror --dry-run --dir ./offline --from-registry registry1.example.com:5000 --to-registry registry2.example.com:5000"   
    echo "" 
    exit 1
}

#
# Parses the CLI arguments for 'mirror' action
#
parse_image_arguments() {

    if [[ "$#" == 0 ]]; then
        print_image_mirror_usage
        exit 1
    fi
    
    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        mirror)
            shift
            IMAGE_MIRROR_ACTION_CALLED="true"
            do_image_mirror "$@"
            break
            ;;
        -h | --help)
            print_image_mirror_usage
            exit 1
            ;;
        *)
            print_image_mirror_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses the CLI arguments for 'mirror' action
#
parse_image_mirror_arguments() {
    if [[ "$#" == 0 ]]; then
        print_image_mirror_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        --image)
            shift
            IMAGE="$1"
            ;;
        --csv)
            shift
            IMAGE_CSV_FILE="$1"
            ;;
        --dir)
            shift
            CASE_ARCHIVE_DIR="$1"
            ;;
        --archive)
            shift
            CASE_ARCHIVE="$1"
            ;;
        --ns-replace)
            shift
            NAMESPACE_ACTION="replace"
            NAMESPACE_ACTION_VALUE="$1"
            ;;
        --ns-prefix)
            shift
            NAMESPACE_ACTION="prefix"
            NAMESPACE_ACTION_VALUE="$1"
            ;;
        --ns-suffix)
            shift
            NAMESPACE_ACTION="suffix"
            NAMESPACE_ACTION_VALUE="$1"
            ;;
        --from-registry)
            shift
            SOURCE_REGISTRY="$1"
            ;;
        --to-registry)
            shift
            TARGET_REGISTRY="$1"
            ;;
        --split-size)
            shift
            OC_TMP_IMAGE_MAP_SPLIT_SIZE=$1
            ;;
        --show-registries)
            SHOW_REGISTRIES=true
            ;;
        --show-registries-namespaces)
            SHOW_REGISTRIES_NAMESPACES=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;
        --groups)
            shift
            IMAGE_GROUPS="$1"
            ;;
        --arch)
            shift
            IMAGE_ARCHS="$1"
            ;;
        --skip-delta)
            shift
            SKIP_DELTA="$1"
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        -h | --help)
            print_image_mirror_usage
            exit 1
            ;;
        *)
            print_image_mirror_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Validates the CLI arguments for 'mirror' action
#
validate_image_mirror_arguments() {
    if [[ -z "${TARGET_REGISTRY}" && -z "${SHOW_REGISTRIES_NAMESPACES}" ]]; then
        log_error "The target registry was not specified"
        exit 1
    fi

    if [ -z "${IMAGE}" ] && [ -z "${IMAGE_CSV_FILE}" ] && [ -z "${CASE_ARCHIVE_DIR}" ]; then
        log_error "One of --image or --csv or --case-dir parameter must be specified"
        exit 1
    fi

    if [ ! -z "${IMAGE_CSV_FILE}" ] && [  ! -z "${CASE_ARCHIVE_DIR}" ]; then
        log_error "Only --csv or --case-dir parameter should be specified"
        exit 1
    fi

    if [ ! -z "${IMAGE_CSV_FILE}" ] && [ ! -f "${IMAGE_CSV_FILE}" ]; then
        log_error "Invalid image CSV file: ${IMAGE_CSV_FILE}"
        exit 1
    fi

    if [ ! -z "${CASE_ARCHIVE_DIR}" ] && [ ! -d "${CASE_ARCHIVE_DIR}" ]; then
        log_error "Invalid CASE archive directory: ${CASE_ARCHIVE_DIR}"
        exit 1
    fi

    if [ ! -z "${CASE_ARCHIVE}" ] && [[ ( ${CASE_ARCHIVE} != *.tgz ) ]]; then
        log_error "Invalid CASE archive: ${CASE_ARCHIVE}"
        exit 1
    fi

    if [ ! -z "${NAMESPACE_ACTION}" ] && [ -z "${NAMESPACE_ACTION_VALUE}" ]; then
        log_error "Missing an argument for namespace ${NAMESPACE_ACTION}"
        exit 1
    fi

    if [ ! -z "${SHOW_REGISTRIES}" ] && [  ! -z "${SHOW_REGISTRIES_NAMESPACES}" ]; then
        log_error "Only one of --show-registries or --show-registries-namespaces parameter may be specified"
        exit 1
    fi

    split_size=$(echo "${OC_TMP_IMAGE_MAP_SPLIT_SIZE}" | grep -E "^\-?[0-9]?\.?[0-9]+$")
    if [ -z "${split_size}" ] || [[ ${OC_TMP_IMAGE_MAP_SPLIT_SIZE} -lt 0 ]]; then
        log_error "Invalid split size"
        exit 1
    fi
}

#
# Validate required tools for image mirroring
#
validate_image_mirror_required_tools() {
    if [ -f "${OC_TMP_IMAGE_MAP}.CATALOG" ]; then
        catalog_images=$(cat "${OC_TMP_IMAGE_MAP}.CATALOG" | grep "=olm-catalog=")

        if [[ ! -z "${catalog_images}" ]]; then
            # validate required tools - skopeo
            skopeo_command=$(command -v skopeo 2> /dev/null)
            if [ -z "${skopeo_command}" ];
            then
                log_error "skopeo not found. For RHEL, use 'sudo yum install skopeo' to install"
                exit 1
            fi
        fi
    fi
}

#
# Updates image namespace
#
update_image_namespace() {
    image="$1"
    if [ ! -z "${NAMESPACE_ACTION_VALUE}" ]; then
        if [ "${NAMESPACE_ACTION}" == "replace" ]; then
            image=$(echo "${image}" | sed -E "s/([^\/]*)\//${NAMESPACE_ACTION_VALUE}\//")
        elif [ "${NAMESPACE_ACTION}" == "prefix" ]; then
            image=$(echo "${image}" | sed -E "s/([^\/]*)\//${NAMESPACE_ACTION_VALUE}\1\//")
        elif [ "${NAMESPACE_ACTION}" == "suffix" ]; then
            image=$(echo "${image}" | sed -E "s/([^\/]*)\//\1${NAMESPACE_ACTION_VALUE}\//")
        fi
    fi
    echo "${image}"
}

# ---------- Configure cluster functions ----------

#
# Handles 'cluster' action
#
do_cluster() {
    parse_cluster_arguments "$@"
}

#
# Applies image content source policy
#
do_cluster_apply_image_policy() {
    # parses arguments
    parse_cluster_apply_image_policy_arguments "$@"
    
    # validates arguments
    validate_cluster_apply_image_policy_arguments

    if [ ! -z "${DRY_RUN}" ]; then
        dry_run_cluster_apply_image_policy
    else 
        run_cluster_apply_image_policy
    fi
}

generate_content_source_image_policy_file() {
    printf "apiVersion: operator.openshift.io/v1alpha1\n" > "${OC_TMP_IMAGE_POLICY}"
    printf "kind: ImageContentSourcePolicy\n" >> "${OC_TMP_IMAGE_POLICY}"
    printf "metadata:\n" >> "${OC_TMP_IMAGE_POLICY}"
    printf "  name: ${IMAGE_POLICY_NAME}\n" >> "${OC_TMP_IMAGE_POLICY}"
    printf "spec:\n" >> "${OC_TMP_IMAGE_POLICY}"
    printf "  repositoryDigestMirrors:\n" >> "${OC_TMP_IMAGE_POLICY}"

    # generates reduced image mapping file without image name
    for line in $(cat ${OC_TMP_IMAGE_MAP}); do
        source_image=$(echo "${line}" | cut -d '=' -f1 | cut -d '/' -f1,2)
        mirror_image=$(echo "${line}" | cut -d '=' -f2 | cut -d '/' -f1,2)
        printf "${source_image}=${mirror_image}\n" >> "${OC_TMP_IMAGE_MAP}_reduced"
    done

    # generates content source image mapping rules
    for line in $(cat "${OC_TMP_IMAGE_MAP}_reduced" | sort -u); do
        source_image=$(echo "${line}" | cut -d '=' -f1)
        mirror_image=$(echo "${line}" | cut -d '=' -f2)
        printf "  - mirrors:\n" >> "${OC_TMP_IMAGE_POLICY}"
        printf "    - ${mirror_image}\n" >> "${OC_TMP_IMAGE_POLICY}"
        printf "    source: ${source_image}\n" >> "${OC_TMP_IMAGE_POLICY}"
    done
}

dry_run_cluster_apply_image_policy() {
    # generates image mapping file
    if [ ! -z "${IMAGE}" ]; then
        process_single_image_mapping
    elif [ ! -z "${IMAGE_CSV_FILE}" ]; then
        process_case_csv_file "${IMAGE_CSV_FILE}"
        check_filter
        generate_image_mapping_file
    elif [ ! -z $CASE_ARCHIVE_DIR ]; then
        process_case_archive_dir
        generate_image_mapping_file
    fi

    # generates content source image policy yaml
    if [ -f "${OC_TMP_IMAGE_MAP}" ]; then
        generate_content_source_image_policy_file

        configure_dry_run_output "3-configure-cluster-airgap" "apply-image-policy"
         # print the policy
        commands=()
        log_info "Generating image content source policy"
        if [ -z "${DRY_RUN_OUTPUT}"]; then
            echo ""
            cat ${OC_TMP_IMAGE_POLICY}
            echo ""
            commands+=("oc apply -f <GENERATED_ICSP_FILE>")
        else
            icsp="${DRY_RUN_OUTPUT}/3-configure-cluster-airgap/apply-image-policy/icsp.yaml"
            $(cat "${OC_TMP_IMAGE_POLICY}" > "$icsp") 
            commands+=("# Generate and apply image content source policy")
            commands+=("oc apply -f \"${icsp}\"")
        fi
        print_dry_run_commands "${commands[@]}"
    else
        log_error "No image mapping found"
        exit 1
    fi
}

run_cluster_apply_image_policy(){
    # generates image mapping file
    if [ ! -z "${IMAGE}" ]; then
        process_single_image_mapping
    elif [ ! -z "${IMAGE_CSV_FILE}" ]; then
        process_case_csv_file "${IMAGE_CSV_FILE}"
        check_filter
        generate_image_mapping_file
    elif [ ! -z $CASE_ARCHIVE_DIR ]; then
        process_case_archive_dir
        generate_image_mapping_file
    fi

    # generates content source image policy yaml
    if [ -f "${OC_TMP_IMAGE_MAP}" ]; then
        generate_content_source_image_policy_file

        # print the policy
        log_info "Generating image content source policy"
        echo "---"
        cat "${OC_TMP_IMAGE_POLICY}"
        echo "---"

        # apply oc command
        log_info "Applying image content source policy"
        adjust_dry_run_flag 'apply'
        oc_cmd="oc apply ${DRY_RUN} -f \"${OC_TMP_IMAGE_POLICY}\"" 
        log_debug "Running: ${oc_cmd}"
        eval ${oc_cmd}

        if [[ "$?" -ne 0 ]]; then
            exit 11
        fi
    else
        log_error "No image mapping found"
        exit 1
    fi
}

#
# Updates cluster global pull secret
#
do_cluster_update_pull_secret() {
    # parses arguments
    parse_cluster_update_pull_secret_arguments "$@"
    
    # validates arguments
    validate_cluster_update_pull_secret_arguments

    if [ ! -z "${DRY_RUN}" ]; then
        dry_run_cluster_update_pull_secret
    else
        run_cluster_update_pull_secret
    fi
}

dry_run_cluster_update_pull_secret() {
    configure_dry_run_output "3-configure-cluster-airgap" "update-pull-secret"
    commands=()
    commands+=("# Retrieve cluster pull secret")
    commands=("oc -n openshift-config get secret/pull-secret -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode | tr -d \"\r|\n| \"")
    commands+=("# Retrieve target registry authentication secret")
    registry_secret_file="${AUTH_DATA_PATH}/secrets/${TARGET_REGISTRY}.json"
    commands+=("cat \"${registry_secret_file}\" | tr -d \"\r|\n| \" | sed -e \"s/^{\\\"auths\\\":{//\" | sed -e \"s/}}$//\"")
    commands+=("# Merge cluster pull secret")
    commands+=("# Save new target registry authentication secret or overwrite with a new one")
    commands+=("echo \"[current secret]\" | sed \"s/\"${TARGET_REGISTRY}\":[^}]*}/[registry secret]/")
    commands+=("echo \"[new secret]\" > \"${OC_TMP_PULL_SECRET}\"")
    commands+=("# Update cluster pull secret")
    adjust_dry_run_flag 'set data'
    oc_cmd="oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${OC_TMP_PULL_SECRET}" 
    commands+=("${oc_cmd}")
    print_dry_run_commands "${commands[@]}"
}

run_cluster_update_pull_secret() {
    # get existing cluster pull secret
    log_info "Retrieving cluster pull secret"
    current_pull_secret=$(oc -n openshift-config get secret/pull-secret -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode | tr -d "\r|\n| ")

    log_info "Retrieving target registry authentication secret"
    registry_secret_file="${AUTH_DATA_PATH}/secrets/${TARGET_REGISTRY}.json"
    registry_pull_secret=$(cat "${registry_secret_file}" | tr -d "\r|\n| " | sed -e "s/^{\"auths\":{//" | sed -e "s/}}$//")

    log_info "Merging cluster pull secret"

    if [[ "${current_pull_secret}" =~ "\"${TARGET_REGISTRY}\":" ]]; then
        log_info "Target registry authentication secret already present in the cluster. Overwriting the secret with a new one"
        new_pull_secret=$(echo "${current_pull_secret}" | sed "s/\"${TARGET_REGISTRY}\":[^}]*}/${registry_pull_secret}/")
    else
        new_pull_secret=$(echo "${current_pull_secret}" | sed -e "s/}}$//")
        new_pull_secret=$(echo "${new_pull_secret},${registry_pull_secret}}}")
    fi
    
    echo "${new_pull_secret}" > "${OC_TMP_PULL_SECRET}"
    # apply oc command
    log_info "Updating cluster pull secret"
    adjust_dry_run_flag 'set data'
    oc_cmd="oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${OC_TMP_PULL_SECRET}" 
    log_debug "Running: ${oc_cmd}"
    eval ${oc_cmd}

    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi
}

#
# Adds registry certificate authority to cluster
#
do_cluster_add_ca_cert() {
    # parses arguments
    parse_cluster_add_ca_cert_arguments "$@"
    
    # validates arguments
    validate_cluster_add_ca_cert_arguments

    if [ ! -z "${DRY_RUN}" ]; then
        dry_run_cluster_add_ca_cert
    else
        run_cluster_add_ca_cert
    fi
}

dry_run_cluster_add_ca_cert() {
    configure_dry_run_output "3-configure-cluster-airgap" "add-ca-cert"
    commands=()
    commands+=("# extract ca certificate and check for configmap with existing registries")
    commands+=("oc -n openshift-config get configmap | grep \"${REGISTRY_CA_CONFIGMAP}\"")
    commands+=("# create or update configmap ${REGISTRY_CA_CONFIGMAP}")
    commands+=("oc -n openshift-config create configmap ${REGISTRY_CA_CONFIGMAP} --from-file=${registry_key}=${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}-ca.crt ")
    commands+=("# Updating cluster image configuration")
    adjust_dry_run_flag 'patch'
    commands+=("oc patch image.config.openshift.io/cluster --patch \"{\"spec\":{\"additionalTrustedCA\":{\"name\":\"${REGISTRY_CA_CONFIGMAP}\"}}}\" --type=merge ${DRY_RUN}")
    print_dry_run_commands "${commands[@]}"
}

run_cluster_add_ca_cert() {
    # extracts ca certificate
    extract_ca_cert

    # checks for registries CAs configmap
    ca_configmap=$(oc -n openshift-config get configmap | grep "${REGISTRY_CA_CONFIGMAP}")

    # creates or updates registry ca configmap
    if [ -z "${ca_configmap}" ]; then
        log_info "Creating configmap ${REGISTRY_CA_CONFIGMAP}"
        adjust_dry_run_flag 'create'
        oc_cmd="oc -n openshift-config create configmap ${REGISTRY_CA_CONFIGMAP} --from-file=${registry_key}=${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}-ca.crt ${DRY_RUN}"
        log_debug "Running: ${oc_cmd}"
        eval ${oc_cmd}

        if [[ "$?" -ne 0 ]]; then
            exit 11
        fi
    else
        log_info "Updating configmap ${REGISTRY_CA_CONFIGMAP}"
        adjust_dry_run_flag 'create'
        oc -n openshift-config create configmap "${REGISTRY_CA_CONFIGMAP}" --from-file="${registry_key}=${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}-ca.crt" \
          --dry-run -o yaml > "${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}.yaml"
        adjust_dry_run_flag 'patch'
        oc -n openshift-config patch configmap "${REGISTRY_CA_CONFIGMAP}" -p "$(cat ${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}.yaml)" ${DRY_RUN}

        if [[ "$?" -ne 0 ]]; then
            rm "${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}.yaml"
            exit 11
        else
            rm "${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}.yaml"
        fi
    fi

    log_info "Updating cluster image configuration"
    adjust_dry_run_flag 'patch'
    oc patch image.config.openshift.io/cluster --patch "{\"spec\":{\"additionalTrustedCA\":{\"name\":\"${REGISTRY_CA_CONFIGMAP}\"}}}" --type=merge ${DRY_RUN}

    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi
}

#
# Deletes registry certificate authority to cluster
#
do_cluster_delete_ca_cert() {
    # parses arguments
    parse_cluster_delete_ca_cert_arguments "$@"

    if [ ! -z "${DRY_RUN}" ]; then
        dry_run_do_cluster_delete_ca_cert
    else 
        # validates arguments
        validate_cluster_delete_ca_cert_arguments
        run_do_cluster_delete_ca_cert
    fi
}

dry_run_do_cluster_delete_ca_cert() {
    configure_dry_run_output "3-configure-cluster-airgap" "delete-ca-cert"
    commands=()
    commands+=("# Validate cluster delete-ca-cert command arguments")
    commands+=("# Search for CAs registries configmap")
    commands+=("oc -n openshift-config get configmap | grep \"${REGISTRY_CA_CONFIGMAP}\"")
    commands+=("# Search for the CA cert")
    commands+=("oc -n openshift-config get configmap \"${REGISTRY_CA_CONFIGMAP}\" -o jsonpath=\"{.data}\" | grep \"[registry key]\"")
    
    commands+=("# Deleting certificate authority for registry ${TARGET_REGISTRY}")
    adjust_dry_run_flag 'patch'
    commands+=("# Patch configmap")
    commads+=("oc -n openshift-config patch configmap \"${REGISTRY_CA_CONFIGMAP}\" \
      --type=json -p=\"[{\"op\": \"remove\", \"path\": \"/data/[registry key]\"}]\" ${DRY_RUN}")
    print_dry_run_commands "${commands[@]}"
}

run_do_cluster_delete_ca_cert() {
    # computes registry key
    registry_key=$(echo "${TARGET_REGISTRY}" | sed -e "s|:|..|")

    log_info "Deleting certificate authority for registry ${TARGET_REGISTRY}"
    adjust_dry_run_flag 'patch'
    oc -n openshift-config patch configmap "${REGISTRY_CA_CONFIGMAP}" \
      --type=json -p="[{\"op\": \"remove\", \"path\": \"/data/${registry_key}\"}]" ${DRY_RUN}

    if [[ "$?" -ne 0 ]]; then
        exit 11
    fi
}

#
# Extracts CA certificate from a server
#
extract_ca_cert() {
    # creates auth data path
    if [ ! -d "${AUTH_DATA_PATH}" ] || [ ! -d "${AUTH_DATA_PATH}/certs" ]; then
        mkdir -p "${AUTH_DATA_PATH}/certs"
    fi

    # computes registry key
    registry_key=$(echo "${TARGET_REGISTRY}" | sed -e "s|:|..|")

    # checks for default registry port
    if [[ ! "${TARGET_REGISTRY}" =~ .*":".* ]]; then
        TARGET_REGISTRY="${TARGET_REGISTRY}:443"
    fi

    # extracts ca from the registry server
    log_info "Extracting certificate authority from ${TARGET_REGISTRY} ..."
    openssl s_client -connect ${TARGET_REGISTRY} -showcerts 2>/dev/null </dev/null \
      | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p;' | cat -n | sort -nr | cut -f2  \
      | sed -ne '1,/-BEGIN CERTIFICATE-/p' | cat -n | sort -nr | cut -f2  > "${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}-ca.crt"

    # checks for return code
    if [ -s "${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}-ca.crt" ]; then
        log_info "Certificate authority saved to ${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}-ca.crt"
    else
        rm "${AUTH_DATA_PATH}/certs/${TARGET_REGISTRY}-ca.crt"
        log_error "Unable to retrieve certificates from ${TARGET_REGISTRY}"
        exit 11
    fi
}

#
# Prints usage menu for 'cluster' action
#
print_cluster_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} cluster [apply-image-policy|update-pull-secret|add-ca-cert|delete-ca-cert]"
    echo ""
    echo "Configure an OpenShift cluster to use with a private registry"
    echo ""
    echo "Options:"
    echo "   apply-image-policy   Apply an image content source policy to use with a private registry"
    echo "   update-pull-secret   Update global cluster pull secret"
    echo "   add-ca-cert          Add a registry certificate authority to the cluster"
    echo "   delete-ca-cert       Delete a registry certificate authority from the cluster"
    echo "   -h, --help           Print usage information"
    echo ""
}

#
# Prints usage menu for 'apply-image-policy' action
#
print_cluster_apply_image_policy_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} cluster apply-image-policy --name POLICY_NAME"
    echo "       [--dry-run] [--image IMAGE|--csv IMAGE_CSV_FILE|--dir CASE_ARCHIVE_DIR]"
    echo "       [--ns-replace NAMESPACE|--ns-prefix PREFIX|--ns-suffix SUFFIX]"
    echo "       --registry TARGET_REGISTRY"
    echo "       [--log-level LOG_LEVEL]"
    echo ""
    echo "Apply an image content source policy to use with a mirrored registry"
    echo ""
    echo "Options:"
    echo "   -n, --name string          Policy name"
    echo "   --image string             A single image"
    echo "   --csv string               CASE images CSV file"
    echo "   --dir string               CASE archive directory that contains the image CSV files"
    echo "   --ns-replace string        Replace the namespace of the mirror image"
    echo "   --ns-prefix string         Append a prefix to the namespace of the mirror image"
    echo "   --ns-suffix string         Append a suffix to the namespace of the mirror image"       
    echo "   --registry string          The mirrored registry"
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   --dry-run                  Print the actions that would be taken with their results"
    echo "   --dry-run-output string    If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help                 Print usage information"
    echo ""
    echo "Example:"
    echo "${script_name} cluster apply-image-policy --name cp-app --dry-run --dir ./offline --registry registry.example.com:5000"
    echo ""
}

#
# Prints usage menu for 'update-pull-secret' action
#
print_cluster_update_pull_secret_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} cluster update-pull-secret --registry TARGET_REGISTRY"
    echo ""
    echo "Update global cluster pull secret for a mirrored registry"
    echo ""
    echo "Options:"
    echo "   --registry string          The mirrored registry"   
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   --dry-run                  Print the actions that would be taken with their results"
    echo "   --dry-run-output string    If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help                 Print usage information"
    echo ""
}

#
# Prints usage menu for 'add-ca-cert' action
#
print_cluster_add_ca_cert_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} cluster add-ca-cert --registry TARGET_REGISTRY"
    echo ""
    echo "Add the certificate authority of a target registry server to the cluster"
    echo ""
    echo "Options:"
    echo "   --registry string          The target registry"   
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   --dry-run                  Print the actions that would be taken with their results"
    echo "   --dry-run-output string    If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help                 Print usage information"
    echo ""
}

#
# Prints usage menu for 'delete-ca-cert' action
#
print_cluster_delete_ca_cert_usage() {
    script_name=`basename ${0}`
    echo "Usage: ${script_name} cluster delete-ca-cert --registry TARGET_REGISTRY"
    echo ""
    echo "Delete the certificate authority of a target registry server from the cluster"
    echo ""
    echo "Options:"
    echo "   --registry string          The target registry"   
    echo "   -l, --log-level string     Set the log level, options are ERROR, WARN, INFO, DEBUG. Default is INFO."
    echo "   --dry-run                  Print the actions that would be taken with their results"
    echo "   --dry-run-output string    If specified, the output of dry run will be saved to given directory"
    echo "   -h, --help                 Print usage information"
    echo ""
}

#
# Parses the CLI arguments for 'cluster' action
#
parse_cluster_arguments() {
    if [[ "$#" == 0 ]]; then
        print_cluster_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        apply-image-policy)
            shift
            SKIP_DELTA="true"
            do_cluster_apply_image_policy "$@"
            break
            ;;
        update-pull-secret)
            shift
            do_cluster_update_pull_secret "$@"
            break
            ;;
        add-ca-cert)
            shift
            do_cluster_add_ca_cert "$@"
            break
            ;;
        delete-ca-cert)
            shift
            do_cluster_delete_ca_cert "$@"
            break
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        -h | --help)
            print_cluster_usage
            exit 1
            ;;
        *)
            print_cluster_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses the CLI arguments for 'apply-image-policy' action
#
parse_cluster_apply_image_policy_arguments() {
    if [[ "$#" == 0 ]]; then
        print_cluster_apply_image_policy_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        -n | --name)
            shift
            IMAGE_POLICY_NAME="$1"
            ;;      
        --image)
            shift
            IMAGE="$1"
            ;;
        --csv)
            shift
            IMAGE_CSV_FILE="$1"
            ;;
        --dir)
            shift
            CASE_ARCHIVE_DIR="$1"
            ;;
        --ns-replace)
            shift
            NAMESPACE_ACTION="replace"
            NAMESPACE_ACTION_VALUE="$1"
            ;;
        --ns-prefix)
            shift
            NAMESPACE_ACTION="prefix"
            NAMESPACE_ACTION_VALUE="$1"
            ;;
        --ns-suffix)
            shift
            NAMESPACE_ACTION="suffix"
            NAMESPACE_ACTION_VALUE="$1"
            ;;
        --registry)
            shift   
            TARGET_REGISTRY="$1"
            ;;            
        --dry-run)
            DRY_RUN=true
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        -h | --help)
            print_cluster_apply_image_policy_usage
            exit 1
            ;;
        *)
            print_cluster_apply_image_policy_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses the CLI arguments for 'update-pull-secret' action
#
parse_cluster_update_pull_secret_arguments() {
    if [[ "$#" == 0 ]]; then
        print_cluster_update_pull_secret_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        --registry)
            shift   
            TARGET_REGISTRY="$1"
            ;;            
        --dry-run)
            DRY_RUN=true
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        -h | --help)
            print_cluster_update_pull_secret_usage
            exit 1
            ;;
        *)
            print_cluster_update_pull_secret_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses the CLI arguments for 'add-ca-cert' action
#
parse_cluster_add_ca_cert_arguments() {
    if [[ "$#" == 0 ]]; then
        print_cluster_add_ca_cert_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        --registry)
            shift   
            TARGET_REGISTRY="$1"
            ;;     
        --dry-run)
            DRY_RUN=true
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;
        -h | --help)
            print_cluster_add_ca_cert_usage
            exit 1
            ;;
        *)
            print_cluster_add_ca_cert_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Parses the CLI arguments for 'delete-ca-cert' action
#
parse_cluster_delete_ca_cert_arguments() {
    if [[ "$#" == 0 ]]; then
        print_cluster_delete_ca_cert_usage
        exit 1
    fi

    # process options
    while [ "$1" != "" ]; do
        case "$1" in
        --registry)
            shift   
            TARGET_REGISTRY="$1"
            ;;     
        --dry-run)
            DRY_RUN=true
            ;;
        -l | --log-level)
            shift
            LOG_LEVEL=$1
            ;;
        --dry-run-output)
            shift
            DRY_RUN_OUTPUT="$1"
            ;;
        -h | --help)
            print_cluster_delete_ca_cert_usage
            exit 1
            ;;
        *)
            print_cluster_delete_ca_cert_usage
            exit 1
            ;;
        esac
        shift
    done
}

#
# Validates the CLI arguments for 'apply-image-policy' action
#
validate_cluster_apply_image_policy_arguments() {
    if [ -z "${IMAGE_POLICY_NAME}" ]; then
        log_error "The policy name was not specified"
        exit 1
    fi

    if [ -z "${IMAGE}" ] && [ -z "${IMAGE_CSV_FILE}" ] && [ -z "${CASE_ARCHIVE_DIR}" ]; then
        log_error "One of --image or --csv or --case-dir parameter must be specified"
        exit 1
    fi

    if [ ! -z "${IMAGE_CSV_FILE}" ] && [  ! -z "${CASE_ARCHIVE_DIR}" ]; then
        log_error "Only --csv or --case-dir parameter should be specified"
        exit 1
    fi

    if [ ! -z "${IMAGE_CSV_FILE}" ] && [ ! -f "${IMAGE_CSV_FILE}" ]; then
        log_error "Invalid image CSV file: ${IMAGE_CSV_FILE}"
        exit 1
    fi

    if [ ! -z "${CASE_ARCHIVE_DIR}" ] && [ ! -d "${CASE_ARCHIVE_DIR}" ]; then
        log_error "Invalid CASE archive directory: ${CASE_ARCHIVE_DIR}"
        exit 1
    fi

    if [ ! -z "${NAMESPACE_ACTION}" ] && [ -z "${NAMESPACE_ACTION_VALUE}" ]; then
        log_error "Missing an argument for namespace ${NAMESPACE_ACTION}"
        exit 1
    fi

    if [ -z "${TARGET_REGISTRY}" ]; then
        log_error "The target registry was not specified"
        exit 1
    fi
}

#
# Validates the CLI arguments for 'update-pull-secret' action
#
validate_cluster_update_pull_secret_arguments() {
    if [ -z "${TARGET_REGISTRY}" ]; then
        log_error "The target registry was not specified"
        exit 1
    fi

    if [ ! -f "${AUTH_DATA_PATH}/secrets/${TARGET_REGISTRY}.json" ]; then
        log_error "Target registry authentication secret not found"
        exit 1
    fi
}

#
# Validates the CLI arguments for 'add-ca-cert' action
#
validate_cluster_add_ca_cert_arguments() {
    if [ -z "${TARGET_REGISTRY}" ]; then
        log_error "The target registry was not specified"
        exit 1
    fi
}

#
# Validates the CLI arguments for 'delete-ca-cert' actions
#
validate_cluster_delete_ca_cert_arguments() {
    if [ -z "${TARGET_REGISTRY}" ]; then
        log_error "The target registry was not specified"
        exit 1
    fi

    # checks for registries CAs configmap
    ca_configmap=$(oc -n openshift-config get configmap | grep "${REGISTRY_CA_CONFIGMAP}")
    if [ -z "${ca_configmap}" ]; then
        log_error "Configmap ${REGISTRY_CA_CONFIGMAP} not found"
        exit 1
    fi

    # checks the existance of the ca cert
    registry_key=$(echo "${TARGET_REGISTRY}" | sed -e "s|:|..|")
    ca_cert=$(oc -n openshift-config get configmap "${REGISTRY_CA_CONFIGMAP}" -o jsonpath="{.data}" | grep "${registry_key}")

    if [ -z "${ca_cert}" ]; then
        log_error "Certificate authority for ${TARGET_REGISTRY} not found"
        exit 11
    fi
}

#
# Checks OC command help text and applies proper dry-run option based on it
#
adjust_dry_run_flag() {
    if [[ ! -z $DRY_RUN ]]; then
        dry_run_help_text=$(oc $1 --help | grep -E "\-\-dry\-run")
        if [[ $dry_run_help_text == *"\"client\""* || $dry_run_help_text == *"'client'"* ]]; then
            DRY_RUN='--dry-run=client'
        fi
    fi
}


#
# Prints or saves to file commands that would be executed as a result of actions if dry run wasn't enabled
#
print_dry_run_commands() {
    y=$#
    for (( x=0; x<y; x++ )); do
        commands_list[x]="$1"
        shift
    done
    if [[ -z $dir_name ]]; then
        log_info "[DRY RUN] Commands that would be executed with dry run disabled:"
        for (( A=0; A<${#commands_list[*]}; A++ )); do
            echo "${commands_list[$A]}"
        done
    else
        log_info "[DRY RUN] Saving commands that would be executed with dry run disabled to $dir_name"

        for (( A=0; A<${#commands_list[*]}; A++ )); do
            echo "${commands_list[$A]}" >> "$dir_name/commands.txt"
        done
    fi
}

adjust_debug_logging_flag() {
    if [ ! -z $CLOUDCTL_TRACE ]; then
        if [ $CLOUDCTL_TRACE == true ]; then
            OC_DEBUG_LOGGING="--loglevel 999"
            SKOPEO_DEBUG_LOGGING="--debug"
        fi
    fi
}

# --- Run ---

main $*
