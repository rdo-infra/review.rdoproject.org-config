#!/bin/bash

for i in {1..60}; do
    echo "Ensuring that containers are spawned... ${i}"
    not_running_pods=$(/usr/bin/oc get pods --no-headers --all-namespaces | grep -viE 'running|complete')
    count=$(echo "$not_running_pods" | sed '/^$/d' | wc -l)
    if [ "$count" -eq "0" ]; then
        echo "Cluster seems to be running"
        exit 0
    else
        echo -e "Some core CRC pods are not ready...\n$not_running_pods"
        sleep 10
    fi
done

echo -e "\nSomthing is not deployed in CRC. Exit!\n"
exit 1
