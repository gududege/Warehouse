FROM bitnami/azure-cli
#switch root to install nslookup and ping command in image
USER root
RUN apt update && apt install -y bind9-dnsutils iputils-ping && rm -rf /var/cache/apt/*
WORKDIR /azure
COPY script .
ENV RUNNING_MODE="monitor"\
    AZURE_RESOURCE_GROUP_ID=""\
    AZURE_APP_ROLE="Contributor"\
    AZURE_APP_NAME="Azure_RefreshIP"\
    AZURE_APP_ID=""\
    AZURE_APP_SECERT=""\
    AZURE_APP_TENANT_ID=""\
    AZURE_VM_ID=""\
    AZURE_VM_DOMAIN_NAME=""\
    LOG_LEVEL="info"\
    CYCLE_TIME=15\
    TZ=Asia/Shanghai
ENTRYPOINT ["bash","/azure/docker-entrypoint.sh"]