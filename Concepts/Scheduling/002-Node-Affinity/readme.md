## Node Affinity
Node affinity is like node selector but with more expressive rules (not just simple matching) and 
an option to decide whether the rule defined is "required" or "preferred". 
This gives the scheduler the ability to schedule pods even if labels are not exactly matched.

The two types of node affinity currently available are:

** requiredDuringSchedulingIgnoredDuringExecution: **
Only schedules a new pod if the rules match; else the pod will go in a pending state. 
Old pods which were already running on nodes before labels were applied will continue to run.

** preferredDuringSchedulingIgnoredDuringExecution: **
Will try to match a pod to a node but if no exact match found, it will still schedule the pod to a node. 
Old pods which were already running on nodes before labels were applied will continue to run.

With an example. Removing the old pod and changing its definition:

``` shell
$ nano node-affinity-with-required.yaml

apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: diskCapacity
            operator: In
            values:
            - low
            - medium
  containers:
  - name: nginx-container
    image: nginx

$ kubectl create -f node-affinity-with-required.yaml

$ kubectl get pods -o wide
```

Remember that our node "mycluster-worker" still has the label "diskCapacity=high". 
But now the pod definition wants to schedule a pod on nodes with the label "diskCapacity=low" or "diskCapacity=medium".

Create the pod with "kubectl create -f node-affinity.yaml" command. 
Now, look at the created pod. As the scheduler could not find a suitable node, the pod has its status set to "Pending".

``` shell
$ kubectl get pods -o wide
```

To investigate this in more detail, run the command "kubectl describe pod <yourPodName>".

Next, let's delete the old pod with "kubectl delete pod <yourPodName>" and try to change our yaml file to make our rules less rigid. 
Let's do this with the help of "preferredDuringSchedulingIgnoredDuringExecution" node affinity.

``` shell
$ nano node-affinity-with-preffered.yaml

apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  affinity:
    nodeAffinity:
      prefferedDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        prefference:
        - matchExpressions:
          - key: diskCapacity
            operator: In
            values:
            - low
            - medium
  containers:
  - name: nginx-container
    image: nginx
```

The value against the "weight" field (ranges between 1-100) is considered while calculating the score 
via priority functions used by the scheduler to decide which node is best for hosting the pod.

Try creating a pod with this yaml and you'll notice that the pod will be scheduled on a node successfully, 
even though no nodes have labels exactly as defined in the pod definition.

``` shell
$ kubectl apply -f node-affinity-with-preffered.yaml

$ kubectl get pods -o wide
```
