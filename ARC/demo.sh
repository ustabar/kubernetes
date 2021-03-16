#!/bin/bash

export clusterName="myakscluster"
export resourceGroup="new-arc-rg"
export configName="mygitconfig"

SUBSCRIPTION_ACCOUNT=$(az account show)
SUBSCRIPTION_ID=$(echo "$SUBSCRIPTION_ACCOUNT" | jq -r .id)
# echo $SUBSCRIPTION_ACCOUNT
# echo $SUBSCRIPTION_ID

export subId=$SUBSCRIPTION_ID

export AzureArcClusterResourceId="/subscriptions/$subId/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$clusterName"
export ServicePrincipalAppId="xxxx"
export ServicePrincipalPassword="xxxx"
export ServicePrincipalTenantId="xxxx"

# Run the following command to use an existing Log Analytics workspace and without specifying a proxy server
export laName="new-arc-la"
export kubeContext="myakscluster"
export logAnalyticsWorkspaceResourceId="/subscriptions/$subId/resourceGroups/$resourceGroup/providers/microsoft.operationalinsights/workspaces/$laName"
export azureArcClusterResourceId="/subscriptions/$subId/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$clusterName"

#################################################
#
# 1- how to on-board kubernetes to Azure Arc
# https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster
#
#################################################

# a- OnBoard K8s cluster to azure ARC using Az CLI
#
# Install the following Azure Arc enabled Kubernetes CLI extensions of versions
#
az extension add --name connectedk8s
az extension add --name k8s-configuration

#
# To update these extensions to the latest version, run the following commands
#
az extension update --name connectedk8s
az extension update --name k8s-configuration

#
# Register the two providers for Azure Arc enabled Kubernetes
#
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration

#
# Monitor the registration process. Registration may take up to 10 minutes.
#
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table

#
# Connect your Kubernetes cluster to Azure Arc
# https://docs.microsoft.com/en-us/cli/azure/ext/k8s-configuration/k8s-configuration?view=azure-cli-latest
#

az connectedk8s connect --name $clusterName --resource-group $resourceGroup

# b- List onboarded cluster
#
# Check arc status
#
az connectedk8s list -g $resourceGroup -o table
# Name          Location    ResourceGroup
# ------------  ----------  ---------------
# target-cls1   westeurope  new-arc-rg
# k8sonlinuxbm  westeurope  new-arc-rg
# myakscluster  westeurope  new-arc-rg
# K8sOnMyWin10  westeurope  new-arc-rg

# c- AKS & Docker Desktop samples

# d- Verify configuration on cluster
#
kubectl get deployments -n azure-arc 
kubectl get pods -n azure-arc 

# e- CleanUp resources
#
az connectedk8s delete --name $clusterName --resource-group $resourceGroup

az connectedk8s connect --name dockerdesktop --resource-group myResourceGroup2
az connectedk8s delete --name myakscluster --resource-group myResourceGroup2

#################################################
#
# 2- enable GitOps on Arc Enabled Kubernetes
# https://github.com/ustabar/hello_arc/blob/master/releases/prod/hello-arc.yaml
#
#################################################
helm list -A
# helm uninstall -n prod hello-arc-prod
kubectl get pods,deployments,services -A

az k8s-configuration list \
           --resource-group $resourceGroup \
           --cluster-name $clusterName \
           --cluster-type connectedClusters

export operatorParams="--git-poll-interval 3s --git-readonly"
export repositoryUrl="https://github.com/ustabar/hello_arc"
export helmOperatorParams="--set helm.versions=v3"

az k8s-configuration create \
           --resource-group "$resourceGroup" \
           --cluster-name "$clusterName" \
           --cluster-type connectedClusters \
           --name "$configName" \
           --operator-type flux \
           --operator-params "$operatorParams" \
           --repository-url "$repositoryUrl" \
           --enable-helm-operator true \
           --scope cluster \
           --helm-operator-params "$helmOperatorParams"

az k8s-configuration delete \
           --resource-group "$resourceGroup" \
           --cluster-name "$clusterName" \
           --cluster-type connectedClusters \
           --name "$configName" \
           --yes

az k8s-configuration update \
           --resource-group "$resourceGroup" \
           --cluster-name "$clusterName" \
           --cluster-type connectedClusters \
           --name "$configName" \
           --enable-helm-operator false \
           --repository-url https://github.com/ustabar/hello_arc \
           --operator-params "$operatorParams"

#################################################
#
# 3- Policy deployment
#https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes
#
#################################################

# a- Define a policy saying deploy an app from github
#    [Preview]: Deploy GitOps to Kubernetes...

# Provider register: Register the Azure Policy provider
az provider register --namespace 'Microsoft.PolicyInsights'

# Assign 'Policy Insights Data Writer (Preview)' role assignment to the Azure Arc enabled Kubernetes cluster
az ad sp create-for-rbac --role "Policy Insights Data Writer (Preview)" \
    --scopes "/subscriptions/$subId/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$clusterName"

# Add the Azure Policy Add-on repo to Helm
helm repo add azure-policy https://raw.githubusercontent.com/Azure/azure-policy/master/extensions/policy-addon-kubernetes/helm-charts

# In below command, replace the following values with those gathered above.
#    <AzureArcClusterResourceId> with your Azure Arc enabled Kubernetes cluster resource Id. For example: /subscriptions/<subscriptionId>/resourceGroups/<rg>/providers/Microsoft.Kubernetes/connectedClusters/<clusterName>
#    <ServicePrincipalAppId> with app Id of the service principal created during prerequisites.
#    <ServicePrincipalPassword> with password of the service principal created during prerequisites.
#    <ServicePrincipalTenantId> with tenant of the service principal created during prerequisites.

# Install the Azure Policy Add-on using Helm Chart
helm install azure-policy-addon azure-policy/azure-policy-addon-arc-clusters \
    --set azurepolicy.env.resourceid="$AzureArcClusterResourceId" \
    --set azurepolicy.env.clientid="$ServicePrincipalAppId" \
    --set azurepolicy.env.clientsecret="$ServicePrincipalPassword" \
    --set azurepolicy.env.tenantid="$ServicePrincipalTenantId"

# azure-policy pod is installed in kube-system namespace
kubectl get pods -n kube-system

# gatekeeper pod is installed in gatekeeper-system namespace
kubectl get pods -n gatekeeper-system

# Get the azure-policy pod name installed in kube-system namespace
kubectl logs azure-policy-8474bd44b6-8d8px -n kube-system

# Get the gatekeeper pod name installed in gatekeeper-system namespace
kubectl logs gatekeeper-audit-7dfcc8c59-gctrj -n gatekeeper-system

###
#
# Demo for policy...
#
###
kubectx docker-desktop
kubectl get nodes
kubectl node-shell docker-desktop
whoami
id -u

kubectx myakscluster
kubectl get nodes
k node-shell aks-nodepool1-25136335-vmss000000

# spawning "nsenter-742f9i" on "aks-nodepool1-25136335-vmss000000"
# Error from server ([denied by azurepolicy-psp-container-no-privilege-esc-8100f6bb1eb9b8825f0b] 
# Privilege escalation container is not allowed: nsenter): admission webhook "validation.gatekeeper.sh" denied the request: 
# [denied by azurepolicy-psp-container-no-privilege-esc-8100f6bb1eb9b8825f0b] Privilege escalation container is not allowed: nsenter

#  b- OnBoard a cluster to Azure Arc

#  c- Check if the poicy is applied to the onboarded cluster

#################################################
#
# 4- Enable Monitoring using bash
# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-enable-arc-enabled-clusters
#
#################################################
# a- Enable monitoring using bash scripts

# Download and save the script to a local folder that configures your cluster with the monitoring add-on
curl -o enable-monitoring.sh -L https://aka.ms/enable-monitoring-bash-script

# Before go to the next step, create a Loag Analytics Workspace on Azure

#
bash enable-monitoring.sh --resource-id "$azureArcClusterResourceId" --kube-context "$kubeContext" --workspace-id "$logAnalyticsWorkspaceResourceId"

# 
# Enable Monitor feature fails because of helm usage!!
# First delete all the resources
#
kubectl delete sa omsagent -n kube-system
kubectl delete secret omsagent-secret -n kube-system
kubectl delete deployments -n kube-system omsagent-rs

#
# We have to debug the bash script starting with "set -x" and ending with "set +x" usage
# Than we changed helm command from "helm update --install" to "helm template"
# and copy the output as YAML file
# we deployed the YAML file using "kubectl apply -f output.yaml"
#

## helm upgrade --install $releaseName --set omsagent.domain=$omsAgentDomainName,omsagent.proxy=$proxyEndpoint,
## omsagent.secret.wsid=$workspaceGuid,omsagent.secret.key=$workspaceKey,omsagent.env.clusterId=$clusterResourceId,
## omsagent.env.clusterRegion=$clusterRegion $helmChartRepoPath

helm template azmon-containers-release-1 --set omsagent.domain=opinsights.azure.com,omsagent.secret.wsid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,omsagent.secret.key=xxxxxxxxxx==,omsagent.env.clusterId=/subscriptions/xxxx-xxxx-xxxx-xxxx-xxxx/resourceGroups/new-arc-rg/providers/Microsoft.Kubernetes/connectedClusters/myakscluster,omsagent.env.clusterRegion=westeurope ./azuremonitor-containers > helm-out.yaml
kubectl apply -f helm-out.yaml 
kubectl delete -f helm-out.yaml 

# b- Show monitoring screen and explain different tabs and contents

# c- Define an alert and create a pod with error, show mail instance

# d- Disable monitoring using bash scripts
# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-optout-hybrid

curl -o disable-monitoring.sh -L https://aka.ms/disable-monitoring-bash-script
bash disable-monitoring.sh --resource-id "$azureArcClusterResourceId" --kube-context "$kubeContext"

#

export AzureArcClusterResourceId="/subscriptions/$subId/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$clusterName"
export ServicePrincipalAppId="60fff875-e754-40b3-9958-a9b62727dd9c"
export ServicePrincipalPassword="9ffPm8gydN-8R6~6X5R_gK0BVvUxDeFV1C"
export ServicePrincipalTenantId="1b221e6c-b574-471a-b0ca-2422717219b8"
helm install azure-policy-addon azure-policy/azure-policy-addon-arc-clusters \
    --set azurepolicy.env.resourceid="$AzureArcClusterResourceId" \
    --set azurepolicy.env.clientid="$ServicePrincipalAppId" \
    --set azurepolicy.env.clientsecret="$ServicePrincipalPassword" \
    --set azurepolicy.env.tenantid="$ServicePrincipalTenantId"
