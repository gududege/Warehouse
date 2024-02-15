FROM amazon/aws-cli
#switch root to install nslookup and ping command in image
USER root
RUN yum update -y && yum install -y iputils bind-utils jq && yum clean all
WORKDIR /aws-script
COPY script .
ENV  AWS_ACCESS_KEY=""\
    AWS_ACCESS_SECERT=""\
    AWS_REGION=""\
    AWS_VM_INSTANCE_ID=""\
    AWS_VM_DOMAIN_NAME=""\
    IPV4=true\
    IPV6=false\
    IGNORE_ERROR=true\
    IPV6_TEST_URL="6.ipw.cn"\
    LOG_LEVEL="info"\
    NOTICE_LEVEL="warning"\
    BARK_URL=""\
    CYCLE_TIME=15\
    TZ=Asia/Shanghai
ENTRYPOINT ["bash","/aws-script/docker-entrypoint.sh"]