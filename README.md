# Example Xilinx FPGA operator

This is a Phase I proof-of-concept/minimum viable product operator that installs the Xilinx FPGA driver(s) and [device plugin](https://github.com/Xilinx/FPGA_as_a_Service/tree/master/k8s-fpga-device-plugin/) on a specific cluster worker node configuration.

TODOs:

- [ ] The extended resource resource limit for the example pod is hard-coded to a particular device name/version. This needs to be extracted automatically from the worker node description.
- [ ] Automate the flashing of the development target platform to the FPGA card.

## Prerequisites

1. [operator-sdk](https://sdk.operatorframework.io/) installed
1. Firmware manually flashed to the FPGA card. This step is currently manual because it requires a *cold* reboot of the host machine.
1. (Optional): Docker installed to build and push images[^1]

## Build driver container image[^1]

```bash
cd driver-container/
DRIVER_IMAGE_NAME=cablelabs/adrenaline_xilinx-fpga-rhel7  # (or your driver image name)                                    
docker build -t $DRIVER_IMAGE_NAME .
docker push $DRIVER_IMAGE_NAME
```

## Build and deploy operator

First, make sure your current context namespace is where you want to deploy the operator's pods:

```bash
kubectl config get-contexts
kubectl config current-context
```

Otherwise, use `kubectl config set-context` to change it.

Change to the operator directory:

```bash
cd xilinx-operator-example/
```

Then, build and push the operator image:[^1]

[^1]: Not necessary for demonstration purposes or if the driver container will not be modified.

```bash
export IMG=cablelabs/adrenaline_xilinx-operator  # (or your operator image name)
make docker-build docker-push
```

Finally, run the operator and create a custom resource:

```bash
export IMG=cablelabs/adrenaline_xilinx-operator  # (or your operator image name)
make install
make deploy
kubectl apply -f config/samples/xilinxtestoperators_v1alpha1_xilinxtestoperator.yaml
```

Check the operator logs:[^2]

```bash
kubectl -n xilinx-operator-example-system logs deployment.app/xilinx-operator-example-controller-manager manager
```

Check to see if the pods are running:

```
kubectl get pods
```

You should see ` xilinx-driver-container-job-xxxxx` and `xilinx-test-pod`.

Watch the driver container logs with:

```
kubectl logs xilinx-driver-container-job-xxxxx -f
```

## Test the FPGA driver

After everything is working, connect to the example pod...

```bash
kubectl exec -it xilinx-test-pod bash
```

...and run commands to verify the FPGA is accessible from the container:

```bash
source /opt/xilinx/xrt/setup.sh
xbutil list
```

# Cleaning up

To remove the various operator artifacts, run:

```bash
kubectl delete -f config/samples/xilinxtestoperators_v1alpha1_xilinxtestoperator.yaml
make undeploy
```

That will remove everything but the [extended resource](https://kubernetes.io/docs/tasks/administer-cluster/extended-resource-node/) on the worker node. To remove that, run `kubectl proxy` (in a separate terminal) and then:

```bash
curl --header "Content-Type: application/json-patch+json" \
--request PATCH \
--data '[{"op": "remove", "path": "/status/capacity/xilinx.com~1fpga-xilinx_vcu1525_dynamic_5_1-1521279439"}]' \
http://localhost:8001/api/v1/nodes/worker-0.test.cablelabs.com/status
```

There is also an [ansible playbook](k8s_delete.yml) that will attempt to clean up after the operator is removed. This playbook assumes the pods were run in the default namespace.

# Development workflow

As there is no way to perform unit tests on the ansible code, iterating rapid deployment to a working cluster is required. Once the operator is deployed, changes can quickly be tested by performing and repeating the following steps:

1. Modify operator code/ansible YAML files.
2. Build and push operator image to docker hub via: `make docker-build docker-push`
3. Delete current operator pod, e.g., `kubectl -n xilinx-operator-example-system delete pod xilinx-operator-example-controller-manager-7c76b86688-xxxxx`
4. Check logs[^2] with `kubectl -n xilinx-operator-example-system logs deployment.app/xilinx-operator-example-controller-manager manager`
5. Repeat as necessary.

[^2]: Just because the operator manager succeeded doesn't necessarily mean that the tasks completed successfully. Please check the logs of the pods that are launched by the operator to ensure that the driver was installed. For example, doing a `kubectl describe pod xilinx-driver-container-job-xxxxx` will let you know if the driver job has run or if it is pending due to taints or node selector mismatch.

# Other Notes

This is a useful command to verify hardware availability: `sudo lspci -vd 10ee:`