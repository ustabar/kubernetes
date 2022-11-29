## Node Selector
Node Selector is the simplest way to make pods schedule on specific nodes. 
This is achieved by using a direct match of key-value pairs against pods and nodes. 
Let us take an example. Suppose we have a node named "node01" in our k8s cluster. 
We can get this information with the command mentioned below:

``` shell
$ kubectl get nodes
NAME                      STATUS   ROLES           AGE   VERSION
mycluster-control-plane   Ready    control-plane   95d   v1.24.0
mycluster-worker          Ready    <none>          95d   v1.24.0
mycluster-worker2         Ready    <none>          95d   v1.24.0
mycluster-worker3         Ready    <none>          95d   v1.24.0
```

Now we would want to assign a label to node "node01" in the form of key-value pair. 
Suppose we want to assign a label with the key "diskCapacity" and with the value "high". 
The command to achieve this will be:

``` shell
$ kubectl label node mycluster-worker diskCapacity=high
$ kubectl describe node mycluster-worker
Name:               mycluster-worker
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    diskCapacity=high
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=mycluster-worker
                    kubernetes.io/os=linux
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: unix:///run/containerd/containerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
```

We have successfully labelled our node.
Now for our pod to run on this node we need to specify a "nodeSelector" field under the "spec" field of the pod definition.

``` shell
$ nano node-selector.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    diskCapacity: high

$ kubectl create -f node-selector.yaml

$ kubectl get pods -o wide
```

As we can see the pod is scheduled on mycluster-worker, which is what we were trying to accomplish.
