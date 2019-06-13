#!/bin/bash
##
# Script to connect to the first Mongod instance running in a container of the
# Kubernetes StatefulSet, via the Mongo Shell, to initalise a MongoDB Replica
# Set and create a MongoDB admin user.
#
# IMPORTANT: Only run this once 3 StatefulSet mongod pods are show with status
# running (to see pod status run: $ kubectl get all)
##

# Check for password argument
if [ $# -lt 2 ] ; then
    echo 'You must provide two arguments, one for the environment and the other for the number of replicas'
    echo '  Usage:  configure.sh dev 1'
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

COUNTER=0
MEMBER_SET=""
SERVICE="mongodb-service.${ENV}.svc.cluster.local:27017"
while [  $COUNTER -lt ${2} ]; do
    MEMBER_SET='{_id: '"${COUNTER}"', host: "mongod-'"${COUNTER}"'.'"${SERVICE}"'"},'"${MEMBER_SET}"
    let COUNTER=COUNTER+1 
done


# Initiate replica set configuration
echo "Configuring the MongoDB Replica Set"
kubectl $CREDENTIAL_ARGS exec mongod-0 -c mongod-container --namespace=$ENV -- mongo --eval 'rs.initiate({_id: "omicsrs", version: 1, members: [ '"${MEMBER_SET%?}"' ]});'

# Wait a bit until the replica set should have a primary ready
echo "Waiting for the Replica Set to initialise..."
sleep 30
kubectl $CREDENTIAL_ARGS exec mongod-0 -c mongod-container --namespace=$ENV -- mongo --eval 'rs.status();'

# Create the admin user (this will automatically disable the localhost exception)
kubectl $CREDENTIAL_ARGS exec mongod-0 -c mongod-container --namespace=$ENV -- bash -c 'mongo --eval "db.getSiblingDB(\"admin\").createUser({user:\"$DDI_MONGO_USER\",pwd:\"$DDI_MONGO_PASSWD\",roles:[{role:\"root\",db:\"admin\"}]});"'
echo

