## Pod AffinityTaint and Toleration
Taint and Tolerations are used together to avoid/allow pod/s to land on certain nodes. 
We attach taints to nodes and define tolerations in our pod definition. 
To understand how this works, let us imagine *rooms as nodes, pods as people, the locks of the room as taints, and keys to those locks as toleration*. 
Let us suppose these people want to get into a room.

If you don’t want people(pods) to get into specific room/s(node/s) you would want to put lock/s(taint/s) on them(nodes). However, if you want to allow specific people to enter a room, you would need to provide them with the key(toleration) to that specific lock/s in the room.

**NOTE:** <br/>
Room/s(node/s) can have zero or more lock/s(taint/s). A room with zero lock means any person(pod/s) can go inside without any key/s(toleration/s).

Let try implementing this in our Kubernetes cluster. 
First, clean your cluster and remove any pods already running. 
We want to check if any taints are already attached to our nodes. 
We can check using the **'kubectl describe node <nodeName>'** command.

A taint comprises three parts: a **key**, a **value**, and an **effect**.

Key and value could be anything you want, but the effect can be one of the following. <br/><br/>
**NoSchedule:**<br/> If pod/s do not tolerate these, then k8 will not schedule those pods on the tainted nodes with this effect.

**PreferNoSchedule:**<br/> This acts as a soft version of ‘NoSchedule.’ If the pod/s do not tolerate these, then k8 will prefer not to schedule those pods on the tainted nodes with this effect.

**NoExecute:**<br/> This will make k8 not schedule pods without matching tolerations on the tainted nodes and will also remove already running pods from that node that do not have the matching tolerations to this effect.

Now that we know the structure of a taint let us taint our nodes with the following commands.

``` shell
$ kubectl taint node <nodeName> <taint>:<effect>
```

We will taint use 'key1=value1:NoSchedule,' and 'key2=value2:NoSchedule' taints for 'node01' and 'controlplane,' respectively.

``` shell
$ kubectl taint node node01 key1=value1:NoSchedule 
node/node01 tainted
```

``` shell
$ kubectl taint node controlplane key2=value2:NoSchedule 
node/controlplane tainted
```

Let's try scheduling pods on these tainted nodes. 
We will try to run our pod ('name=pod1') by providing toleration to node node01's taint 
(i.e.:' key1=value1:NoSchedule').

Let’s also try to run a second pod ('name=pod2') and provide it toleration against the taint of the node control-plane (i.e.: 'key2=value2:NoSchedule'). The yaml definitions of these pods will be as attached below:

``` shell
apiVersion: v1
kind: Pod
metadata:
  name: pod1
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  tolerations:
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "NoSchedule"
``` 

``` shell
apiVersion: v1
kind: Pod
metadata:
  name: pod2
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  tolerations:
  - key: "key2"
    operator: "Equal"
    value: "value2"
    effect: "NoSchedule"
``` 

Create these pods using the 'kubectl create -f <pod-definition. yaml>' command. 
Try to get the status of these pods by running the command 'kubectl get pods -o wide.'

``` shell
$ kubectl get pods -o wide
``` 

As we can see, these pods landed on those nodes against which they had tolerations defined in their yaml files. 
But what happens if a pod doesn’t have toleration to any of the node’s taints?

Let's try this out. For this, we will create a new pod without any tolerations defined. 
The yaml definition of the pod is given below.

**Note:** Our nodes will still have previously applied taints.

``` shell
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-no-toleration
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
``` 

Try creating this pod with the help of the 'kubectl create -f <pod-definition.yaml>' command. 
Let us also check the status of pods with 'kubectl get pods -o wide.'

``` shell
$ kubectl get pods -o wide
``` 

Our new pod (name=pod-with-no-tolerations) has gone into the pending state because 
Kubernetes could not find any suitable node for it.

Let's make our rules less rigid by adding a new taint **('key2=value2:PreferNoSchedule')** to the node **'controlplane'** and removing the previous taint **('key2=value2:NoSchedule')**. 
To achieve this, run the following commands in sequence.

* kubectl taint node control-plane key2=value2:PreferNoSchedule
* kubectl taint node control-plane key2=value2:NoSchedule-

Now, let’s again check the status of the pods.

``` shell
$ kubectl taint node controlplane key2=value2:PreferNoSchedule
node/controlplane tainted
``` 

``` shell
$ kubectl taint node controlplane key2=value2:NoSchedule-
node/controlplane untainted
``` 

``` shell
$ kubectl get pods -o wide
``` 

As we can see, the pod (named 'pod-with-no-tolerations') is in the **'Running'** state. 
This is because the effect 'PreferNoSchedule' is not as strict as 'NoSchedule'.

Now let's try tainting the node **'controlplane'** with the effect of **'NoExecution'** and notice what happens to the pods already running on that node.

``` shell
$ kubectl taint node controlplane key2=value2:NoExecute
node/controlplane tainted
``` 

``` shell
$ kubectl get pods -o wide
``` 

We can observe that the pods (that did not have the toleration against the **'key2=value2:NoExecution'** taint) terminated, just as we discussed at the start of this section.

**References:**<br/><br/>
https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
