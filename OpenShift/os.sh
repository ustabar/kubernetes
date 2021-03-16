az account list -o table

az account set --subscription IDDDDDDD
az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait

LOCATION=eastus                 # the location of your cluster
RESOURCEGROUP=osresgroup        # the name of the resource group where you want to create your cluster
CLUSTER=cluster                 # the name of your cluster

az network vnet create \
   --resource-group $RESOURCEGROUP \
   --name aro-vnet \
   --address-prefixes 10.0.0.0/22

az network vnet subnet create \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --name master-subnet \
  --address-prefixes 10.0.0.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet create \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --name worker-subnet \
  --address-prefixes 10.0.2.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet update \
  --name master-subnet \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --disable-private-link-service-network-policies true

az aro create \
  --resource-group $RESOURCEGROUP \
  --name $CLUSTER \
  --vnet aro-vnet \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet \
  --pull-secret @pull-secret.txt \
  --domain barutos.onmicrosoft.com

az aro create \
  --resource-group MyResourceGroup \
  --name MyCluster \
  --vnet MyVnet \
  --master-subnet MyMasterSubnet \
  --worker-subnet MyWorkerSubnet \
  --worker-count 1 \
  --pull-secret @pullsecret.txt