FROM python:3-slim
#switch root to install nslookup and ping command in image
USER root
RUN apt update && \
    apt install -y cron git expect curl && \
    rm -rf /var/cache/apt/*
RUN pip --no-cache-dir install --upgrade pip && \
    pip --no-cache-dir install ansible ansible-lint
ENV ENV_WORKDIR="/ansible" \
    ENV_GIT_REPOSITORY="" \
    ENV_GIT_TOKEN="" \
    ENV_ANSIBLE_COLLECTIONS="" \
    ENV_PIP_PACKAGES="" \
    ENV_APT_PACKAGES="" \
    ENV_CRON_EXPRESSIONS="" \
    ENV_QUITE_MODE=false \
    TZ="Asia/Shanghai"
COPY docker-entrypoint.sh /opt
WORKDIR ${ENV_WORKDIR}
ENTRYPOINT ["bash","/opt/docker-entrypoint.sh"]