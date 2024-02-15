#!/bin/bash
#set -x
ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata
bash /azure/refreshIP.sh $([ -n "${RUNNING_MODE}" ] && echo " -m ${RUNNING_MODE} " || echo "")\
$([ -n "${AZURE_RESOURCE_GROUP_ID}" ] && echo " -g ${AZURE_RESOURCE_GROUP_ID} " || echo "")\
$([ -n "${AZURE_APP_ROLE}" ] && echo " -r ${AZURE_APP_ROLE} " || echo "")\
$([ -n "${AZURE_APP_NAME}" ] && echo " -n ${AZURE_APP_NAME} " || echo "")\
$([ -n "${AZURE_APP_ID}" ] && echo " -a ${AZURE_APP_ID} " || echo "")\
$([ -n "${AZURE_APP_SECERT}" ] && echo " -s ${AZURE_APP_SECERT} " || echo "")\
$([ -n "${AZURE_APP_TENANT_ID}" ] && echo " -t ${AZURE_APP_TENANT_ID} " || echo "")\
$([ -n "${AZURE_VM_ID}" ] && echo " -v ${AZURE_VM_ID} " || echo "")\
$([ -n "${AZURE_VM_DOMAIN_NAME}" ] && echo " -d ${AZURE_VM_DOMAIN_NAME} " || echo "")\
$([ -n "${CYCLE_TIME}" ] && echo " -c ${CYCLE_TIME} " || echo "")\
$([ -n "${LOG_LEVEL}" ] && echo " -l ${LOG_LEVEL} " || echo "")