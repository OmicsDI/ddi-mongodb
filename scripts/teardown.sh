#!/bin/sh
##
# Script to remove/undepoy all project resources from the local Minikube environment.
##

if [ $# -eq 0 ] ; then
    echo 'You must provide one argument for the environment to be created'
    echo '  Usage:  teardown.sh dev'
    echo
    exit 1
fi

ENV="${1}"
CREDENTIAL_ARGS=""

if [[ -z "${KUBECONFIG}" ]]; then        
    echo "No KUBECONFIG env found."
else
    echo "KUBECONFIG set to ${KUBECONFIG}"
    CREDENTIAL_ARGS="--kubeconfig ${KUBECONFIG}"
fi

# Delete mongod stateful set + mongodb service + secrets + host vm configuer daemonset
kubectl $CREDENTIAL_ARGS delete statefulsets mongod --namespace=$ENV
kubectl $CREDENTIAL_ARGS delete services mongodb-service --namespace=$ENV
kubectl $CREDENTIAL_ARGS delete services mongodb-nodeport --namespace=$ENV
kubectl $CREDENTIAL_ARGS delete secret shared-bootstrap-data --namespace=$ENV
sleep 3

# Delete persistent volume claims
kubectl $CREDENTIAL_ARGS delete persistentvolumeclaims -l role=mongo --namespace=$ENV

if [ "$ENV" = "local" ] ; then
    kubectl $CREDENTIAL_ARGS delete persistentvolume task-pv-volume --namespace=$ENV
fi
