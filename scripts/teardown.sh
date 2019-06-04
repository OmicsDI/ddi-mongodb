#!/bin/sh
##
# Script to remove/undepoy all project resources from the local Minikube environment.
##

if [[ $# -eq 0 ]] ; then
    echo 'You must provide one argument for the environment to be created'
    echo '  Usage:  teardown.sh dev'
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

# Delete mongod stateful set + mongodb service + secrets + host vm configuer daemonset
kubectl $CREDENTIAL_ARGS delete statefulsets mongod --namespace=$ENV
kubectl $CREDENTIAL_ARGS delete services mongodb-service --namespace=$ENV
kubectl $CREDENTIAL_ARGS delete services mongodb-nodeport --namespace=$ENV
kubectl $CREDENTIAL_ARGS delete secret shared-bootstrap-data --namespace=$ENV
sleep 3

# Delete persistent volume claims
kubectl $CREDENTIAL_ARGS delete persistentvolumeclaims -l role=mongo --namespace=$ENV

