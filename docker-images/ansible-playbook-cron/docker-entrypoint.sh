#!/bin/bash
# Update timeozne info
log() {
	if ! $ENV_QUITE_MODE; then
        echo -e "$1"
	fi
}
ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone
if [ $# -eq 0 ]; then
    # Exit if no any args
    exit 1
else
    # Install need packages
    if [ -n "${ENV_APT_PACKAGES}" ]; then
        for pack in ${ENV_APT_PACKAGES}; do
            if ! apt list --installed | grep $pack >> /dev/null; then
                log "######### Installing Debian packages: $pack #########"  
                apt install -y $pack
            fi
        done
    fi
    # Install need packages
    if [ -n "${ENV_PIP_PACKAGES}" ]; then
        for pack in ${ENV_PIP_PACKAGES}; do
            if ! pip list | grep $pack >> /dev/null; then
                log "######### Installing pip package: $pack #########"        
                pip --no-cache-dir install $pack
            fi
        done
    fi
    # Install need packages
    if [ -n "${ENV_ANSIBLE_COLLECTIONS}" ]; then
        for collection in ${ENV_ANSIBLE_COLLECTIONS}; do
            if ! ansible-galaxy collection list | grep $collection >> /dev/null; then
                log "######### Installing ansible collection: $collection #########"
                ansible-galaxy collection install $collection
            fi
        done
    fi
    # Print program info
    if ! $ENV_QUITE_MODE; then
        log "######### Print ansible-playbook information #########"
        ansible-playbook --version >> /proc/1/fd/1
	fi 
    if [ -n "${ENV_CRON_EXPRESSIONS}" ]; then
        # add an 
        log "######### Add below ansible-playbook task to cron  #########"
        log "${ENV_CRON_EXPRESSIONS} root ansible-playbook $@"
        echo "${ENV_CRON_EXPRESSIONS} root ansible-playbook $@ >> /proc/1/fd/1" >> /etc/crontab
        service cron restart >> /dev/null
        log "######### Executing  #########"
        tail -f >> /dev/null
    else
        # Excute command directly
        log "######### Execute ansible-playbook directly #########"
        ansible-playbook $@
    fi
fi
