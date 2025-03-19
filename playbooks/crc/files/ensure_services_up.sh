#!/bin/bash


# In the new CRC version (2.34.1, it is possible that before we inject
# the pull-secret.txt into /var/lib/kubelet/config.json, the openshift-marketplace
# operator would try to re-create pods (the openshift-marketplace operator
# changed the imagePullPolicy to always), which can take long time (over 20 minutes) to
# make the OpenShift cluster up and ready with all deployed operators.
# To avoid waiting for the pods, let's trigger them to remove and
# after recreating, it would be working on first retry.

# Check if OCP version is higher than 4. '14'
OCP_SUBVERSION=$(oc version -o json  | jq -r '.openshiftVersion' | cut -f2 -d'.')
if (( OCP_SUBVERSION > 14 )); then
    for retry in {1..10}; do
        broken_pods=$(oc get pods -n openshift-marketplace --no-headers | grep -viE 'running|completed|init|pending' | awk '{print $1}')
        if [ -n "$broken_pods" ]; then
            echo "Retrying cleaning openshift-marketplace... $retry"
            for i in $broken_pods; do
                oc -n openshift-marketplace delete pod "$i";
            done
            sleep 10
        else
            echo "All marketplace pods are fine"
            break
        fi
    done
fi

for i in {1..60}; do
    echo "Ensuring that containers are spawned... ${i}"
    not_running_pods=$(oc get pods --no-headers --all-namespaces 2>/dev/null | grep -viE 'running|completed')
    if [ -z "$not_running_pods" ]; then
        echo "Cluster seems to be running"
        exit 0
    else
        echo -e "Some core CRC pods are not ready...\n$not_running_pods"
        sleep 10
    fi
done

echo -e "\nSomthing is not deployed in CRC. Exit!\n"
exit 1
