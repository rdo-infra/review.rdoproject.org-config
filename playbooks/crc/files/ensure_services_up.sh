#!/bin/bash

for i in {1..20}; do
    echo "Ensuring that containers are spawned... ${i}"
    count=$(oc get pods --no-headers --all-namespaces | grep -viEc 'running|complete')
    if [ "$count" -eq "0" ]; then
        echo "Cluster seems to be running"
        exit 0
    else
        echo "Some core CRC pods are not ready..."
        sleep 15
    fi
done

echo -e "\nSomthing is not deployed in CRC. Exit!\n"
exit 1
