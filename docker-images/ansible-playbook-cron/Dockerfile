FROM python:3-slim
#switch root to install nslookup and ping command in image
USER root
RUN apt update && \
    apt install -y cron git expect curl && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    pip --no-cache-dir install --upgrade pip && \
    pip --no-cache-dir install ansible ansible-lint
ENV ENV_WORKDIR="/ansible" \
    ENV_GIT_REPOSITORY="" \
    ENV_GIT_TOKEN="" \
    ENV_ANSIBLE_COLLECTIONS="" \
    ENV_PIP_PACKAGES="" \
    ENV_APT_PACKAGES="" \
    ENV_CRON_EXPRESSIONS="" \
    ENV_QUITE_MODE=false \
    ENV_APT_MIRROR=mirrors.ustc.edu.cn \
    ENV_PIP_MIRROR=mirrors.ustc.edu.cn/pypi/web/simple \
    TZ="Asia/Shanghai"
COPY docker-entrypoint.sh /opt
WORKDIR ${ENV_WORKDIR}
ENTRYPOINT ["bash","/opt/docker-entrypoint.sh"]