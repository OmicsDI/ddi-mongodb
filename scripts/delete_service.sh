#!/bin/sh
##
# Script to just undeploy the MongoDB Service & StatefulSet but nothing else.
##

if [ $# -eq 0 ] ; then
    echo 'You must provide one argument for the environment to be created'
    echo '  Usage:  delete_service.sh dev'
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

# Just delete mongod stateful set + mongodb service onlys (keep rest of k8s environment in place)
kubectl $CREDENTIAL_ARGS delete statefulsets mongod --namespace=$ENV
kubectl $CREDENTIAL_ARGS delete services mongodb-service --namespace=$ENV

# Show persistent volume claims are still reserved even though mongod stateful-set has been undeployed
kubectl $CREDENTIAL_ARGS get persistentvolumes --namespace=$ENV

