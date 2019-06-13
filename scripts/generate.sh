#!/bin/sh
##
# Script to deploy a Kubernetes project with a StatefulSet running a MongoDB Replica Set, to a local Minikube environment.
##

if [ $# -eq 0 ] ; then
    echo 'You must provide one argument for the environment to be created'
    echo '  Usage:  generate.sh dev'
    echo
    exit 1
fi

# Create keyfile for the MongoD cluster as a Kubernetes shared secret
TMPFILE=$(mktemp)
ENV="${1}"
CREDENTIAL_ARGS=""

if [[ -z "${KUBECONFIG}" ]]; then        
    echo "No KUBECONFIG env found."
else
    echo "KUBECONFIG set to ${KUBECONFIG}"
    CREDENTIAL_ARGS="--kubeconfig ${KUBECONFIG}"
fi

/usr/bin/openssl rand -base64 741 > $TMPFILE
kubectl $CREDENTIAL_ARGS create secret generic shared-bootstrap-data --from-file=internal-auth-mongodb-keyfile=$TMPFILE --namespace=$ENV
rm $TMPFILE

# Create mongodb service with mongod stateful-set
# TODO: Temporarily added no-valudate due to k8s 1.8 bug: https://github.com/kubernetes/kubernetes/issues/53309
kubectl $CREDENTIAL_ARGS apply -f ../resources/mongodb-service.$ENV.yaml --validate=true --namespace=$ENV
sleep 5

# Print current deployment state (unlikely to be finished yet)
kubectl $CREDENTIAL_ARGS get all --namespace=$ENV
kubectl $CREDENTIAL_ARGS get persistentvolumes --namespace=$ENV
echo
echo "Keep running the following command until all 'mongod-n' pods are shown as running:  kubectl get pods --namespace=$ENV"
echo

