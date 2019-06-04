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
if [[ $# -eq 0 ]] ; then
    echo 'You must provide one argument for the environment to be created'
    echo '  Usage:  configure.sh dev'
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

# Initiate replica set configuration
echo "Configuring the MongoDB Replica Set"
SERVICE="mongodb-service.${ENV}.svc.cluster.local:27017"
kubectl $CREDENTIAL_ARGS exec mongod-0 -c mongod-container --namespace=$ENV -- mongo --eval 'rs.initiate({_id: "omicsrs", version: 1, members: [ {_id: 0, host: "mongod-0.'"${SERVICE}"'"}, {_id: 1, host: "mongod-1.'"${SERVICE}"'"}, {_id: 2, host: "mongod-2.'"${SERVICE}"'"} ]});'

# Wait a bit until the replica set should have a primary ready
echo "Waiting for the Replica Set to initialise..."
sleep 30
kubectl $CREDENTIAL_ARGS exec mongod-0 -c mongod-container --namespace=$ENV -- mongo --eval 'rs.status();'

# Create the admin user (this will automatically disable the localhost exception)
kubectl $CREDENTIAL_ARGS exec mongod-0 -c mongod-container --namespace=$ENV -- bash -c 'mongo --eval "db.getSiblingDB(\"admin\").createUser({user:\"$DDI_MONGO_USER\",pwd:\"$DDI_MONGO_PASSWD\",roles:[{role:\"root\",db:\"admin\"}]});"'
echo

