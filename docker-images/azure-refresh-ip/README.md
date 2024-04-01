## Description
Due to Chinese GFW, the VM public IP shall be banned sometimes. As a result, we need to continuously monitor its IP address, and re-assign a new one from pool once we cannot ping it successfully.
## Requirement
- At least, you need to get resource group ID and target VM ID from Azure.
- For now, this image just supports single IPV4 address monitoring (Because IPV6 is not free tier. LOL).
- Use host network to run this image.
## Installation
1. Pull image from docker hub
```
docker pull lucifer94/azure-cli-refreship:latest
```
2. Run the image once with config mode and your Azure resource group ID.
```
docker run -d -e AZURE_RESOURCE_GROUP_ID=/subscriptions/xxxxxxxx-xxxxx-xxxxxxx-xxxxxxx/resourceGroups/ -e RUNNING_MODE=config  --name azure-cli-refreship lucifer94/azure-cli-refreship:latest
```
3. Then go to the container's log, find the below message and use it to login in your Azure account.
```
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code S2YVJPLKQ to authenticate.
```
4. After login successfully, the script will create a new Azure AD App for later automatically login. Please record the new AD App information shown in the log.
```
{
  "appId": "xxxx-xxxx-xxxxx-xxxxx-xxxxx",
  "displayName": "AZURE_APP_NEW",
  "password": "abcdefghijklmnopqrstuvwxzy",
  "tenant": "xxxx-xxxx-xxxxx-xxxxx-xxxxx"
}
```
5. Delete previous container and use Azure AD App information to create new on with running in monitor mode.
```
docker run -d -e RUNNING_MODE=monitor -e AZURE_APP_ID=xxxx-xxxx-xxxxx-xxxxx-xxxxx -e AZURE_APP_SECERT=abcdefghijklmnopqrstuvwxzy  -e  AZURE_APP_TENANT_ID=xxxx-xxxx-xxxxx-xxxxx-xxxxx
 -e AZURE_VM_ID=/subscriptions/xxxx-xxxx-xxxxx-xxxxx-xxxxx/resourceGroups/resource_name/providers/Microsoft.Compute/virtualMachines/VM_Name -e AZURE_VM_DNS_NAME=www.google.com -e CYCLE_TIME=15 --name azure-cli-refreship lucifer94/azure-cli-refreship:latest
```
## Usage
- In config mode, it's necessary to provider AZURE_RESOURCE_GROUP_ID.
- In monitor mode, it's necessary to provider AZURE_APP_ID, AZURE_APP_SECERT, AZURE_APP_TENANT_ID, AZURE_VM_ID, AZURE_VM_DOMAIN_NAME.

| **key**                 | **description**                                       | **default value** |
|:-----------------------:|:-----------------------------------------------------:|:-----------------:|
| RUNNING_MODE            | config|monitor                                        | monitor           |
| AZURE_RESOURCE_GROUP_ID | Azure resource group ID (only be used in config mode) |                   |
| AZURE_APP_NAME          | New Azure AD App name (only be used in config mode)   | Azure_RefreshIP   |
| AZURE_APP_ROLE          | New Azure AD App role (only be used in config mode)   | Contributor       |
| AZURE_APP_ID            | Azure AD App ID                                       |                   |
| AZURE_APP_SECERT        | Azure AD App secert                                   |                   |
| AZURE_APP_TENANT_ID     | Azure AD App tenant ID                                |                   |
| AZURE_VM_ID             | Azure VM which need to be monitored.                  |                   |
| AZURE_VM_DOMAIN_NAME    | The Domain Name which points to VM public IP          |                   |
| CYCLE_TIME              | monitor cycle time                                    | 15                |
| LOG_LEVEL               | debug|info|warning|error                              | info              |
| TZ                      | time zone                                             | Asia/Shanghai     |
## Road map
- [ ] Monitor multiple VMs in a group
- [ ] Support IPV6