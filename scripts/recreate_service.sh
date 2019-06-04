#!/bin/sh
##
# Script to just deploy the MongoDB Service & StatefulSet back onto the exising Kubernetes cluster.
##

if [[ $# -eq 0 ]] ; then
    echo 'You must provide one argument for the environment to be created'
    echo '  Usage:  recreate_service.sh dev'
    echo
    exit 1
fi

ENV="${1}"
CREDENTIAL_ARGS=""

if [[ ${ENV} != "local" ]]; then
    if [[ -z "${KUBECONFIG}" ]]; then
        echo "You must set the kubernetes config file path before run it in prod cluster instance"
        echo "i.e. export KUBECONFIG=/path/to/your-kubeconfig.yml"
        echo
        exit 1
    else
        CREDENTIAL_ARGS="--kubeconfig ${KUBECONFIG}"        
    fi
fi  

# Show persistent volume claims are still reserved even though mongod stateful-set not deployed
kubectl $CREDENTIAL_ARGS get persistentvolumes --namespace=$ENV

# Deploy just the mongodb service with mongod stateful-set only
kubectl $CREDENTIAL_ARGS apply -f ../resources/mongodb-service.yaml --namespace=$ENV
sleep 5

# Print current deployment state (unlikely to be finished yet)
kubectl $CREDENTIAL_ARGS get all --namespace=$ENV
kubectl $CREDENTIAL_ARGS get persistentvolumes --namespace=$ENV
echo
echo "Keep running the following command until all 'mongod-n' pods are shown as running:  kubectl get all"
echo

