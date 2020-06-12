#!/bin/bash

resourceGroupName="Mythical3Tier_RG"
vnet="Mythical3Tier-vnet"
location="EastUS"
backendSubnet="backendapi-snet"
backendfuncname="mythicalBackEndApi"
backendfuncplanname="BackEndAPI-plan"
middleSubnet="middleapi-snet"
middlefuncname="mythicalMiddleAPI"
middlefuncplanname="MiddleAPI-plan"
storageacctname="mythical3tierstore"
sku="P1v2"

# Create a resource group.
az group create --location $location --name $resourceGroupName

echo "Create VNET & MiddleAPISubnet"
az network vnet create \
 --name $vnet \
 --resource-group $resourceGroupName \
 --subnet-name $middleSubnet    \
 --subnet-prefixes 10.0.0.0/24  \
 --address-prefixes 10.0.0.0/16 

echo "Create BackendSubnet"
az network vnet subnet create -g $resourceGroupName \
                                --vnet-name $vnet \
                                --name $backendSubnet \
                                --address-prefix 10.0.1.0/24

echo "Enable ServiceEndPoints in MiddleApiAppSubnet"
az network vnet subnet update   --name $middleSubnet --vnet-name $vnet \
                                --service-endpoints Microsoft.Web \
                                --resource-group $resourceGroupName

echo "Create Storage Acct"
az storage account create -n $storageacctname -g $resourceGroupName -l $location --sku Standard_LRS

echo "BACKEENDAPI APP"
echo "Create Function App Plan"
az functionapp plan create --name $backendfuncplanname       \
                           --resource-group $resourceGroupName  \
                           --sku $sku       \
                           --is-linux true  \
                           --location $location

echo "Create Function App"
az functionapp create   --name $backendfuncname   \
                        --storage-account  $storageacctname \
                        --plan $backendfuncplanname      \
                        --resource-group $resourceGroupName \
                        --runtime dotnet    \
                        --functions-version 3 \
                        --os-type Linux

echo "BACKEENDAPI APP VNET Integration"
az functionapp vnet-integration add --name $backendfuncname \
                                    --resource-group $resourceGroupName \
                                    --subnet $backendSubnet  \
                                    --vnet  $vnet  \

echo "MIDDLEAPI APP"
echo "Create Function App Plan"
az functionapp plan create --name $middlefuncplanname   \
                           --resource-group $resourceGroupName \
                           --sku $sku  \
                           --is-linux true   \
                           --location $location

echo "Create Function App"
az functionapp create   --name $middlefuncname   \
                        --storage-account  $storageacctname \
                        --plan $middlefuncplanname      \
                        --resource-group $resourceGroupName \
                        --runtime dotnet    \
                        --functions-version 3 \
                        --os-type Linux

echo "Set MiddleAPIApp Appsetting for BackendAPI"
az functionapp config appsettings set --name $middlefuncname \
                                     --resource-group $resourceGroupName \
                                    --settings "BACKENDAPI_URL=$storageConnectionString"

echo "MIDDLEAPI APP VNET Integration"
az functionapp vnet-integration add --name $middlefuncname   \
                                    --resource-group $resourceGroupName  \
                                    --subnet $middleSubnet  \
                                    --vnet  $vnet   

echo "Add IP Restriction on BackEndAPI"
az functionapp config access-restriction add    --name $backendfuncname \
                                                --resource-group $resourceGroupName \
                                                --priority 100 \
                                                --action Allow \
                                                --subnet $middleSubnet \
                                                --vnet  $vnet 




#Enable Service EndPoint
#Such that BackEndApi is a ServiceEndPoint for Middle Api
#https://mythicalbackendapi.azurewebsites.net/api/BackendAPI?code=EaB6xlMkbB6ucZKnqOj112JezS1uZ8pdsoT/robsoa3qd5i82T2P5Q==
#https://<yourapp>.azurewebsites.net/api/<funcname>?clientid=<your key name>
#clientid=EaB6xlMkbB6ucZKnqOj112JezS1uZ8pdsoT/robsoa3qd5i82T2P5Q==
#az functionapp show --name $backendfuncname --resource-group $resourceGroupName
#az functionapp config show --name $backendfuncname --resource-group $resourceGroupName
#az webapp deployment list-publishing-profiles -n $backendfuncname -g $resourceGroupName 
