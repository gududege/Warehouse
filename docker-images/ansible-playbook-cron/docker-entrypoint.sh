#!/bin/bash
# Update timeozne info
log() {
    if ! $ENV_QUITE_MODE; then
        echo -e "$1"
    fi
}
logerr() {
    echo -e "$1"
    exit $2
}
changeMirror(){
    if [[ $(curl -s ipinfo.io/country) == "CN" ]]; then
        log "######### Replace Debian APT mirror #########"
        sed -i "s/deb.debian.org/${ENV_APT_MIRROR}/g" /etc/apt/sources.list.d/debian.sources
        apt update
        log "######### Replace PIP mirror #########"
        pip install -i https://$ENV_PIP_MIRROR pip -U
        pip config set global.index-url https://$ENV_PIP_MIRROR
    fi
}
# Update time zone
ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} >/etc/timezone

if [ $# -eq 0 ]; then
    # Exit if no any args
    logerr "No input arguments" 1
else
    # Change source mirror according to IP location
    changeMirror
    # Install need packages
    if [ -n "${ENV_APT_PACKAGES}" ]; then
        for pack in ${ENV_APT_PACKAGES}; do
            if ! apt list --installed | grep $pack >>/dev/null; then
                log "######### Installing Debian packages: $pack #########"
                apt install -y $pack
            fi
        done
    fi
    # Install need packages
    if [ -n "${ENV_PIP_PACKAGES}" ]; then
        for pack in ${ENV_PIP_PACKAGES}; do
            if ! pip list | grep $pack >>/dev/null; then
                log "######### Installing pip package: $pack #########"
                pip --no-cache-dir install $pack
            fi
        done
    fi
    # Install need packages
    if [ -n "${ENV_ANSIBLE_COLLECTIONS}" ]; then
        for collection in ${ENV_ANSIBLE_COLLECTIONS}; do
            if ! ansible-galaxy collection list | grep $collection >>/dev/null; then
                log "######### Installing ansible collection: $collection #########"
                ansible-galaxy collection install $collection
            fi
        done
    fi
    # Change to workdir
    cd $ENV_WORKDIR
    # Get content from remote repository
    if [ -n "${ENV_GIT_REPOSITORY}" ]; then
        log "######### Get content from remote repository #########"
        if ! $ENV_QUITE_MODE; then
            if [ -n "${ENV_GIT_TOKEN}" ]; then
{
/usr/bin/expect <<EOF
set timeout 120
spawn git clone "${ENV_GIT_REPOSITORY}" "${ENV_WORKDIR}"
expect "Username for"
send "user\n"
expect "Password for"
send "${ENV_GIT_TOKEN}\n"
expect eof
catch wait result
exit [lindex $result 3]
EOF
}
            else
                git clone ${ENV_GIT_REPOSITORY} ${ENV_WORKDIR}
            fi
        else
            if [ -n "${ENV_GIT_TOKEN}" ]; then
{
expect <<EOF 
set timeout 120
spawn git clone "${ENV_GIT_REPOSITORY}" "${ENV_WORKDIR}"
expect "Username for"
send "user\n"
expect "Password for"
send "${ENV_GIT_TOKEN}\n"
expect eof
catch wait result
exit [lindex $result 3]
EOF
}>/dev/null
            else
                git clone ${ENV_GIT_REPOSITORY} ${ENV_WORKDIR} >/dev/null
            fi
        fi
        [ $? -ne 0 ] && logerr "Cannot clone remote repository" 2
    fi
    if ! $ENV_QUITE_MODE; then
        log "######### Print ansible-playbook information #########"
        { ansible-playbook --version; }
    fi
    if [ -n "${ENV_CRON_EXPRESSIONS}" ]; then
        # add an
        log "######### Add below ansible-playbook task to cron  #########"
        log "${ENV_CRON_EXPRESSIONS} root ansible-playbook $@"
        echo "${ENV_CRON_EXPRESSIONS} root ansible-playbook $@ >> /proc/1/fd/1" >>/etc/crontab
        service cron restart >>/dev/null
        log "######### Executing  #########"
        tail -f >>/dev/null
    else
        # Excute command directly
        log "######### Execute ansible-playbook directly #########"
        { ansible-playbook $@; }
    fi
fi