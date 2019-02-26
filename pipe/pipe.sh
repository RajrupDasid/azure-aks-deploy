#!/usr/bin/env bash
#
# a pipe to deploy, using kubectl, to a kubernetes cluster running on azure kubernetes service (aks)
#
# Required globals:
#   NAME
#
# Optional globals:
#   DEBUG (default: "false")
# 

source "$(dirname "$0")/common.sh"

info "Executing the pipe..."

enable_debug() {
  if [[ "${DEBUG}" == "true" ]]; then
    info "Enabling debug mode."
    set -x
  fi
}
enable_debug

# azure service principal
# these are required for at least one execution of the pipe in a step in order to fetch the kube context from the aks cluster
AZURE_APP_ID=${AZURE_APP_ID}
AZURE_PASSWORD=${AZURE_PASSWORD}
AZURE_TENANT_ID=${AZURE_TENANT_ID}

# azure kubernetes cluster AKS
# always required
AZURE_AKS_NAME=${AZURE_AKS_NAME:?'AZURE_AKS_NAME environment variable missing.'}
AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP:?'AZURE_RESOURCE_GROUP environment variable missing.'}

# Kubernetes parameters
KUBECTL_COMMAND=${KUBECTL_COMMAND}
KUBECTL_ARGUMENTS=${KUBECTL_ARGUMENTS}
KUBERNETES_SPEC_FILE=${KUBERNETES_SPEC_FILE}

# default parameters
DEBUG=${DEBUG:="false"}

# look for existing kubeconfig file and re-use, otherwise authenticate to azure and generate one
# a kubeconfig file will exist if this pipe has already run, for the same AKS cluster within this step
if [ ! -f .kube/kubeconfig-"${AZURE_RESOURCE_GROUP}-${AZURE_AKS_NAME}" ]; then

  info "no existing kube config found at .kube/kubeconfig-${AZURE_RESOURCE_GROUP}-${AZURE_AKS_NAME}, retrieving from Azure"

  # check for azure service principal environment variables
  if [[ -z "${AZURE_APP_ID}" ]] || [[ -z "${AZURE_PASSWORD}" ]] || [[ -z "${AZURE_TENANT_ID}" ]]; then
    fail "AZURE_APP_ID, AZURE_PASSWORD, AZURE_TENANT_ID are missing, cannot authenticate to Azure"    
  fi

  # log in to the azure cli
  info "log in the azure cli using service principal"
  run az login --service-principal --username "${AZURE_APP_ID}" --password "${AZURE_PASSWORD}" --tenant "${AZURE_TENANT_ID}"
  if [[ "${status}" != "0" ]]; then  
    fail "Error logging in using azure service principal!"
  fi

  # retrieve the kubernetes config for kube context
  info "retrieve the kube config via the azure cli"
  run az aks get-credentials  --resource-group "${AZURE_RESOURCE_GROUP}" --name "${AZURE_AKS_NAME}" --file .kube/kubeconfig-"${AZURE_RESOURCE_GROUP}-${AZURE_AKS_NAME}" --overwrite-existing
  if [[ "${status}" != "0" ]]; then  
    fail "Unable to retrieve the kubernetes config file from the cluster using az aks get credentials!"
  fi
else
  info "existing kube config detected at .kube/kubeconfig-${AZURE_RESOURCE_GROUP}-${AZURE_AKS_NAME}"
fi

# set the kube context to point to our file
info "setting the kube config current context"
export KUBECONFIG=.kube/kubeconfig-"${AZURE_RESOURCE_GROUP}-${AZURE_AKS_NAME}" 
run kubectl config use-context "${AZURE_AKS_NAME}"

# kubectl command handler
case $KUBECTL_COMMAND in
    "apply")
      if [ -n "$KUBERNETES_SPEC_FILE" ]; then
        info "Applying kubernetes spec from file"
        run kubectl apply -f ${KUBERNETES_SPEC_FILE} ${KUBECTL_ARGUMENTS}
      else
        info "Applying kubernetes spec using command parameter"
        run kubectl apply ${KUBECTL_ARGUMENTS}
      fi
    ;;
    "delete")
      if [ -n "$KUBERNETES_SPEC_FILE" ]; then
        info "Deleting kubernetes spec from file"
        run kubectl delete -f ${KUBERNETES_SPEC_FILE} ${KUBECTL_ARGUMENTS}
      else
        info "Deleting kubernetes spec using command parameter"
        run kubectl delete ${KUBECTL_ARGUMENTS}
      fi
    ;;
    "")
    ;;
    *)
      info "running kubectl command ${KUBECTL_COMMAND} using generic handler"
      run kubectl ${KUBECTL_COMMAND} ${KUBECTL_ARGUMENTS}
    ;;
esac

if [[ "${status}" == "0" ]]; then
  success "Success!"
else
  fail "Error!"
fi
