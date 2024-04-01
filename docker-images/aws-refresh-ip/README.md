# AWS-Refresh-IP

## Description
Due to Chinese GFW, the **AWS EC2** public IP shall be banned sometimes. As a result, we need to continuously monitor its IP address, and re-assign a new one from pool once we cannot ping it successfully.

## Requirement
- At least, you need to get access key, secert and EC2 instance id from AWS.
- Currently, this image refresh ip by restarting EC2 instance, so do not assign Elastic IP to the VM.
- IPV6 support if you want to monitor EC2 IPV6 public address.

## Installation
1. Pull image from docker hub
```
docker pull lucifer94/aws-cli-refreship:latest
```
2. Run the image with some necessary variables
```
docker run -d -e AWS_ACCESS_KEY=xxxxxxxxxxxx -e AWS_ACCESS_SECERT=xxxxxxxxxxxxxxxxxxxx -e AWS_REGION=ap-northeast-1 -e AWS_VM_INSTANCE_ID=i-xxxxxxxxxxx -e AWS_VM_DOMAIN_NAME=xxx.xxxxxxx.xxx -e CYCLE_TIME=15 --name aws-cli-refreship lucifer94/aws-cli-refreship:latest
```

## Usage

|      **key**       |                            **description**                             | **default value** |
| :----------------: | :--------------------------------------------------------------------: | :---------------: |
|   AWS_ACCESS_KEY   |                             AWS Access key                             |                   |
| AWS_ACCESS_SECERT  |                           AWS Access secert                            |                   |
|     AWS_REGION     | [AWS Region](https://docs.aws.amazon.com/general/latest/gr/rande.html) |                   |
| AWS_VM_INSTANCE_ID |                             AWS EC2 VM ID                              |                   |
| AWS_VM_DOMAIN_NAME |                            DNS domain name                             |                   |
|        IPV4        |                     Enable monitoring IPV4 address                     |       true        |
|        IPV6        |                     Enable monitoring IPV6 address                     |       false       |
|    IGNORE_ERROR    |             Doesn't end the script even an error reported              |       true        |
|   IPV6_TEST_URL    |                             IPV6 test url                              |     6.ipw.cn      |
|     CYCLE_TIME     |                           monitor cycle time                           |        15         |
|     LOG_LEVEL      |            docker log level = {debug\|info\|warning\|error}            |       info        |
|    NOTICE_LEVEL    |         Bark server log level = {debug\|info\|warning\|error}          |      warning      |
|      BARK_URL      |                              Bark APP url                              |                   |
|         TZ         |                               time zone                                |   Asia/Shanghai   |

## Road map
- [ ] Add aliyun-ddns script
- [ ] Add EC2 Elastic IP support
- [ ] Add lightsail support