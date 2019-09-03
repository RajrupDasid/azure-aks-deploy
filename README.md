# Bitbucket Pipelines Pipe: Azure AKS Deploy

A pipe that uses kubectl to interact with a Kubernetes cluster running on [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)

## YAML Definition

Add the following snippet to the script section of your `bitbucket-pipelines.yml` file:

```yaml
script:
  - pipe: microsoft/azure-aks-deploy:1.0.2
    variables:
      AZURE_APP_ID: $AZURE_APP_ID
      AZURE_PASSWORD: $AZURE_PASSWORD
      AZURE_TENANT_ID: $AZURE_TENANT_ID
      AZURE_AKS_NAME: '<string>'
      AZURE_RESOURCE_GROUP: '<string>'
      KUBECTL_COMMAND: '<string>'
      KUBECTL_ARGUMENTS: '<string>'
      # KUBERNETES_SPEC_FILE: '<string>' # Optional
      # DEBUG: '<boolean>' # Optional
```

## Variables

| Variable                  | Usage                                                       |
| ------------------------- | ----------------------------------------------------------- |
| AZURE_APP_ID (*)          | The app ID, URL or name associated with the service principal required for login. |
| AZURE_PASSWORD (*)        | Credentials like the service principal password, or path to certificate required for login. |
| AZURE_TENANT_ID  (*)      | The AAD tenant required for login with the service principal. |
| AZURE_AKS_NAME (*)        | Name of the AKS management service to connect to.
| AZURE_RESOURCE_GROUP (*)  | Name of the resource group that the AKS management service is deployed to.  |
| KUBECTL_COMMAND (*)       | The name of the command to execute with kubectl |
| KUBECTL_ARGUMENTS (*)     | Any arguments to be passed to kubectl. |
| KUBERNETES_SPEC_FILE      | A spec file to configure the AKS cluster. |
| DEBUG                     | Turn on extra debug information. Default: `false`. |

_(*) = required variable._

## Prerequisites

You will need to configure required Azure resources before running the pipe. The easiest way to do it is by using the Azure cli. You can either [install the Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) on your local machine, or you can use the [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) provided by the Azure Portal in a browser.

### Service principal

You will need a service principal with sufficient access to create an AKS service, or update an existing AKS service. To create a service principal using the Azure CLI, execute the following command in a bash shell:

```sh
az ad sp create-for-rbac --name MyAKSServicePrincipal
```

Get the resource id for AKS:

```sh
az aks show -g MyResourceGroup -n myakscluster --query id 
"/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/MyResourceGroup/providers/Microsoft.ContainerService/managedClusters/myakscluster"
```

Add the role assignment "Azure Kubernetes Service Cluster User Role" to the service principal and scope to AKS:

```sh
az role assignment create --assignee 00000000-0000-0000-0000-000000000000 --role "Azure Kubernetes Service Cluster User Role" --scope "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/MyResourceGroup/providers/Microsoft.ContainerService/managedClusters/myakscluster"
```

Test the service principal login:

```sh
az login --service-principal --username 00000000-0000-0000-0000-000000000000 --password 00000000-0000-0000-0000-000000000000 --tenant 00000000-0000-0000-0000-000000000000
```

Refer to the following documentation for more detail:

* [Service principals with Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal)
* [Create an Azure service principal with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)

### AKS Instance

Using the service principal credentials obtained in the previous step, you can use the following commands to create an AKS instance in a bash shell:

```bash
az login --service-principal --username ${AZURE_APP_ID}  --password ${AZURE_PASSWORD} --tenant ${AZURE_TENANT_ID}

az group create --name ${AZURE_RESOURCE_GROUP} --location australiaeast

az aks create \
--resource-group ${AZURE_RESOURCE_GROUP} \
--name ${AZURE_AKS_NAME} \
--node-count 1 \
--enable-addons monitoring \
--service-principal ${AZURE_APP_ID} \
--client-secret ${AZURE_PASSWORD} \
--generate-ssh-keys
```

## Examples

### Basic example

```yaml
script:
  - pipe: microsoft/azure-aks-pipe:0.3.2
    variables:
      AZURE_APP_ID: $AZURE_APP_ID
      AZURE_PASSWORD: $AZURE_PASSWORD
      AZURE_TENANT_ID: $AZURE_TENANT_ID
      AZURE_AKS_NAME: 'my-cluster'
      AZURE_RESOURCE_GROUP: 'my-resource-group'
      KUBECTL_COMMAND: 'version'
```

### Advanced example

There are two ways you can deploy a kubernetes spec file to your AKS cluster - either by passing it in the `KUBECTL_ARGUMENTS` variable "`-f filename.yaml`" , or by passing it in the `KUBERNETES_SPEC_FILE` variable.  

Using kubectl command and arguments:

```yaml
script:
  - pipe: microsoft/azure-aks-deploy:1.0.2
    variables:
      AZURE_APP_ID: $AZURE_APP_ID
      AZURE_PASSWORD: $AZURE_PASSWORD
      AZURE_TENANT_ID: $AZURE_TENANT_ID
      AZURE_AKS_NAME: 'my-cluster'
      AZURE_RESOURCE_GROUP: 'my-resource-group'
      KUBECTL_COMMAND: 'apply'
      KUBECTL_ARGUMENTS: '-f azure-vote.yaml'
      DEBUG: 'true'
```

Using kubectl command and kubernetes spec file:

```yaml
script:
  - pipe: microsoft/azure-aks-deploy:1.0.2
    variables:
      AZURE_APP_ID: $AZURE_APP_ID
      AZURE_PASSWORD: $AZURE_PASSWORD
      AZURE_TENANT_ID: $AZURE_TENANT_ID
      AZURE_AKS_NAME: 'my-cluster'
      AZURE_RESOURCE_GROUP: 'my-resource-group'
      KUBECTL_COMMAND: 'apply'
      KUBERNETES_SPEC_FILE: 'azure-vote.yaml'
      DEBUG: 'true'
```

## Support

If you’d like help with this pipe, or you have an issue or feature request, please contact us:

**Option 1** - Azure portal - Goto: https://portal.azure.com

- Go to Help+Support (at the left navigation)
- Click “+New support request”
- Choose Issue Type “Technical”
- Choose Services “All Services”
- Under “Developer Tools” choose “Azure DevOps Services”
- Problem Type, choose “Pipelines”

**Option 2** - Azure DevOps - Goto: https://azure.microsoft.com/en-us/support/create-ticket/

- Choose Azure DevOps Support ticket tile
- Choose the Appropriate “Create an incident” button
- The screen will be pre populated with “Developer Tools” “Azure DevOps”.
- Choose Pipelines as the category and follow the wizard.


If you’re reporting an issue, please include:

- the version of the pipe
- relevant logs and error messages
- steps to reproduce
