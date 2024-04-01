#!/bin/bash
# Update timeozne info
ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone
# Start the script
bash $(dirname $0)/refreship.sh $([ -n "${AWS_ACCESS_KEY}" ] && echo " -k ${AWS_ACCESS_KEY} " || echo "")\
$([ -n "${AWS_ACCESS_SECERT}" ] && echo " -s ${AWS_ACCESS_SECERT} " || echo "")\
$([ -n "${AWS_REGION}" ] && echo " -r ${AWS_REGION} " || echo "")\
$([ -n "${AWS_VM_INSTANCE_ID}" ] && echo " -i ${AWS_VM_INSTANCE_ID} " || echo "")\
$([ -n "${AWS_VM_DOMAIN_NAME}" ] && echo " -d ${AWS_VM_DOMAIN_NAME} " || echo "")\
$( ${IPV4}  && echo " -4 " || echo "")\
$( ${IPV6} && echo " -6 " || echo "")\
$( ${IGNORE_ERROR} && echo " -q " || echo "")\
$([ -n "${BARK_URL}" ] && echo " -b ${BARK_URL} " || echo "")\
$([ -n "${IPV6_TEST_URL}" ] && echo " -u ${IPV6_TEST_URL} " || echo "")\
$([ -n "${CYCLE_TIME}" ] && echo " -c ${CYCLE_TIME} " || echo "")\
$([ -n "${LOG_LEVEL}" ] && echo " -l ${LOG_LEVEL} " || echo "")\
$([ -n "${NOTICE_LEVEL}" ] && echo " -n ${NOTICE_LEVEL} " || echo "")
