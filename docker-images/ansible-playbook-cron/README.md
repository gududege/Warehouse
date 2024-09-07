# Ansible-Playbook-Cron

## Description
Install all given dependencies and run playbook with cron.

## Usage

| **Environment**         | **Description**                              | **Example**                             |
|-------------------------|----------------------------------------------|-----------------------------------------|
| ENV_WORKDIR             | Work Directory (Default is /ansible)         | /opt/ansible                            |
| ENV_GIT_REPOSITORY      | Remote git repository url                    | https://github.com/go-gitea/gitea.git   |
| ENV_GIT_TOKEN           | Token string to access private repo          | xxxxxxxxx                               |
| ENV_APT_PACKAGES        | All Debian packages need to be installed     | curl iputils-ping                       |
| ENV_PIP_PACKAGES        | All pip packages need to be installed        | boto3 botocore                          |
| ENV_ANSIBLE_COLLECTIONS | All ansible collections need to be installed | community.docker community.digitalocean |
| ENV_CRON_EXPRESSIONS    | Cron expression, empty means execute once    | * * * * *                               |
| ENV_QUITE_MODE          | Forbid debug message                         | true                                    |
| ENV_APT_MIRROR          | For CN user, no http/https scheme            | mirrors.ustc.edu.cn                     |
| ENV_PIP_MIRROR          | For CN user, no http/https scheme            | mirrors.ustc.edu.cn/pypi/web/simple     |
| TZ                      | Time zone                                    | Asia/Shanghai                           |
