FROM python:3-slim
#switch root to install nslookup and ping command in image
USER root
RUN pip --no-cache-dir install --upgrade pip &&\
    pip --no-cache-dir install ansible ansible-lint
RUN apt update &&\
    apt install -y cron  &&\
    rm -rf /var/cache/apt/*
ENV ENV_ANSIBLE_COLLECTIONS="" \
    ENV_PIP_PACKAGES="" \
    ENV_APT_PACKAGES=""\
    ENV_CRON_EXPRESSIONS=""\
    ENV_QUITE_MODE=false\
    TZ="Asia/Shanghai"
COPY docker-entrypoint.sh /root
WORKDIR /ansible
ENTRYPOINT ["bash","/root/docker-entrypoint.sh"]