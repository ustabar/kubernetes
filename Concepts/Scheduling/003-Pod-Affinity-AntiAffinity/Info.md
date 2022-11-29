## Pod Affinity
Just like node selectors and node affinity, pod definition uses labels 
assigned to nodes of the k8 cluster to decide which node that specific pod will land on.

Similarly, inter-pod affinity (or anti-affinity) is to be defined in the pod definition 
if you want to schedule (or avoid scheduling in case of anti-affinity) your pods on specific nodes. 
You can do it based on the labels of the pods already running/scheduled on the available cluster nodes.

Let us understand this with an example. 


``` shell
$ kubectl describe pods
```

let's assume that we want to create a pod (with the name "with-pod-affinity") 
such that it lands on a node on which at least one pod is already running 
with a label ("app=nginx") attached to it. 
This can be achieved by defining podAffinity in our pod-definition yaml file.

``` shell
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - nginx
         topologyKey: topology.kubernetes.io/zone
  containers:
  - name: with-pod-affinity
    image: nginx
``` 

Let’s see how pod-anti-affinity works. 
It is the opposite of how the above example works. 
Suppose you don’t want to schedule a new pod (with the name "with-pod-anti-affinity") 
on the node/s on which even one pod is already running with a label (such as "app=nginx") 
attached to it.

This, too, can be achieved by defining podAntiAffinity in our pod-definition yaml file.


``` shell
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-anti-affinity
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - nginx
         topologyKey: topology.kubernetes.io/hostname
  containers:
  - name: with-pod-affinity
    image: nginx
``` 

After creating pods with the help of the "kubeclt create -f <definition_file.yaml>" command 
and the above pod yaml files, let’s ensure they landed on the nodes as intended.

``` shell
$ kubectl get pods -o wide
``` 

As we can observe in the above image, it worked fine, as the pod "with-pod-affinity" 
landed on a node, while the pod "with-pod-anti-affinity" didn’t land on the same node.
