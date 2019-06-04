# MongoDB Deployment Demo for Kubernetes on Minikube (i.e. running on local workstation)

An example project demonstrating the deployment of a MongoDB Replica Set via Kubernetes on Minikube (Kubernetes running locally on a workstation). Contains example Kubernetes YAML resource files (in the 'resource' folder) and associated Kubernetes based Bash scripts (in the 'scripts' folder) to configure the environment and deploy a MongoDB Replica Set.

For further background information on what these scripts and resource files do, plus general information about running MongoDB with Kubernetes, see: [http://k8smongodb.net/](http://k8smongodb.net/)


## 1 How To Run

### 1.1 Prerequisites

1. Make sure you have a Kubernetes instance up and running;
2. Depends on which environment you are about to deploy, create the kubernetes namespace matching with the name of the environment

    ```
    $ kubectl create namespace dev    
    ```
3. Make sure you setted up the Username & Password for the admin user in kubernetes secret
    ```
    Secret name: omicsdi
    Secret key: MONGO_USER
    Secret key: MONGO_PASSWD
    ```
### 1.2 Main Deployment Steps 

1. To deploy the MongoDB Service (including the StatefulSet running "mongod" containers), via a command-line terminal/shell, execute the following:

    ```
    $ cd scripts
    # For dev environment
    $ ./generate.sh dev
    ```

2. Re-run the following command, until all 3 “mongod” pods (and their containers) have been successfully started (“Status=Running”; usually takes a minute or two).

    ```
    $ kubectl get all --namespace=dev
    ```

3. Execute the following script which connects to the first Mongod instance running in a container of the Kubernetes StatefulSet, via the Mongo Shell, to (1) initialise the MongoDB Replica Set, and (2) create a MongoDB admin user.

    ```
    $ ./configure_auth.sh dev
    ```

You should now have a MongoDB Replica Set initialised, secured and running in a Kubernetes StatefulSet.


### 1.3 Redeployment Without Data Loss Test

To see if Persistent Volume Claims really are working, run a script to drop the Service & StatefulSet (thus stopping the pods and their “mongod” containers) and then a script to re-create them again:

    $ ./delete_service.sh dev
    $ ./recreate_service.sh dev
    $ kubectl get all
    
As before, keep re-running the last command above, until you can see that all 3 “mongod” pods and their containers have been successfully started again. Then connect to the first container, run the Mongo Shell and query to see if the data we’d inserted into the old containerised replica-set is still present in the re-instantiated replica set:

    $ kubectl exec -it mongod-0 -c mongod-container bash
    $ mongo
    > db.getSiblingDB('admin').auth("main_admin", "abc123");
    > use test;
    > db.testcoll.find();
    
You should see that the two records inserted earlier, are still present.

### 1.4 Undeploying & Cleaning Down the Kubernetes Environment

Run the following script to undeploy the MongoDB Service & StatefulSet.

    $ ./teardown.sh dev

Reference :-https://github.com/pkdone/minikube-mongodb-demo