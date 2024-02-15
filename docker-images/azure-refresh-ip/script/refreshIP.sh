#!/bin/bash
#set -x
#Azure parameters
resource_group_id=""
appid=""
sercert=""
tenantid=""
vm_ids=""
domain_name=""
domain_ip=""
#script environment
mode="monitor"
app_role="Contributor"
app_name="$(echo $0 | grep -oE [^/]+\.sh)_App_$$"
cycle_time=0
debug_level=4
info_level=3
warn_level=2
error_level=1
log_level=${info_level}
# The first parameter is log message.
# The second parameter is log level.
log() {
	local level=$([ -z "$2" ] && echo ${info_level} || echo $2)
	if [ ${log_level} -ge ${level} ]; then
		local log_level_txt=""
		case ${level} in
		1)
			log_level_txt="error"
			;;
		2)
			log_level_txt="warning"
			;;
		3)
			log_level_txt="info"
			;;
		4)
			log_level_txt="debug"
			;;
		esac
		echo -e "$(date "+%Y-%m-%d %H:%M:%S") ${log_level_txt} $1"
	fi
}
# Restart VM to get new IP address.
freship() {
	# At first deallocate target VM
	log "The VM is deallocating." ${info_level}
	az vm deallocate --ids ${vm_ids}
	# Then startup VM again
	log "The VM is starting." ${info_level}
	az vm start --ids ${vm_ids}
	# Finally, get new IP address
	log "The VM has changed to new IP: ${newip}" ${info_level}
}
connectToAzure() {
	if az login --service-principal --username ${appid} --password ${sercert} --tenant ${tenantid} --output none; then
		log "Login Azure successfully." ${debug_level}
	else
		log "The login information is invaild." ${error_level}
		return 1
	fi
}
disconnect() {
	az logout
	log "Logout Azure." ${debug_level}
}
getPublicIPFromProvider() {
	if domain_ip=$(az vm list-ip-addresses --ids ${vm_ids} --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" --out tsv); then
		log "The VM IP Address get from Azure is ${domain_ip}" ${debug_level}
	else
		log "The VM is not started or VM id is not correct." ${error_level}
		return 1
	fi
}
verifyDNSRecord() {
	if nslookup ${domain_name} >>/dev/null; then
		# The first entry is DNS server ip address.
		local dns_ip_list=$(nslookup ${domain_name} | grep Address | tr "\t" " " | tr -s " " | cut -d " " -f 2 | tail -n +2)
		log "The domain_name IP Address get from DNS is \n${dns_ip_list}" ${debug_level}
		if echo ${dns_ip_list} | grep -wq ${domain_ip}; then
			return 0
		else
			log "The DNS providers doesn't give correct IP address: ${dns_ip}" ${warn_level}
			return 1
		fi
	else
		log "Cannot get DNS record from network." ${error_level}
		return 1
	fi
}
# Check whether current station can connect remote VM.
connectToVM() {
	ping -c 4 ${domain_ip} >>/dev/null
	return $? # Transfer exit code
}
monitor() {
	while true; do
		if connectToAzure && getPublicIPFromProvider && verifyDNSRecord; then
			if connectToVM; then
				log "The VM can be connected." ${info_level}
			else
				log "The VM cannot be connected, start to refresh IP." ${info_level}
				freship
			fi
		fi
		disconnect
		if [ ${cycle_time} -eq 0 ]; then
			break
		else
            log "Wait ${cycle_time} minutes for next check process." ${info_level}
			sleep "${cycle_time}m"
		fi
	done
}
createNewAPP() {
	if az login --use-device-code; then
        log "Login Azure successfully." ${info_level}
        az ad sp create-for-rbac --name ${app_name} --role ${app_role} --scopes ${resource_group_id}
        log "Please record above message." ${info_level}
        disconnect
    else
        log "Please login as soon as possible" ${warn_level}
        return 1
    fi
}
help() {
	echo -e "Usage: Enter configuration mode only if you don't have Azure APP.\n\t-m\tOperating mode={config,monitor}\n\t-g\tResource Group ID (used in configuration mode)\n\t-r\tAPP role in resource group (used in configuration mode)\n\t-n\tAPP name (used in configuration mode)\n\t-a\tAzure APP ID\n\t-s\tAzure APP Secert\n\t-t\tAzure Tenant ID\n\t-v\tAzure VM ID\n\t-h\tDomain name\n\t-c\tMonitor cycle time\n\t-l\tlog level={debug,info,warning,error}"
}
# Get arguments from CLI
while getopts "m:g:r:n:a:s:t:v:d:c:l:" opts; do
	case ${opts} in
	m)
		mode=${OPTARG}
		;;
	g)
		resource_group_id=${OPTARG}
		;;
	r)
		app_role=${OPTARG}
		;;
	n)
		app_name=${OPTARG}
		;;
	a)
		appid=${OPTARG}
		;;
	s)
		sercert=${OPTARG}
		;;
	t)
		tenantid=${OPTARG}
		;;
	v)
		vm_ids=${OPTARG}
		;;
	d)
		domain_name=${OPTARG}
		;;
	c)
		let cycle_time=${OPTARG}
		;;
	l)
		case ${OPTARG} in
		debug)
			log_level=${debug_level}
			;;
		warning)
			log_level=${warn_level}
			;;
		error)
			log_level=${error_level}
			;;
		*)
			log_level=${info_level}
			;;
		esac
		;;
	*)
		help
		exit 1
		;;
	esac
done
#Check all options are provided.
if [[ ${mode} == "monitor" ]]; then
	#log all needed parameters for debugging use.
	log "ALL parameters are: \n\tMode: ${mode} \n\tAzure APP ID: ${appid} \n\tAzure APP Sercert: ${sercert} \n\tAzure Tenant ID: ${tenantid} \n\tAzure VM ID: ${vm_ids} \n\tDomain name: ${domain_name}" ${debug_level}
	if [ -z "${appid}" ] || [ -z "${sercert}" ] || [ -z "${tenantid}" ] || [ -z "${vm_ids}" ] || [ -z "${domain_name}" ]; then
		log "Please enter enough parameters." ${error_level}
		help
		exit 1
	else
		monitor
	fi
elif [[ ${mode} == "config" ]]; then
	#log all needed parameters for debugging use.
	log "ALL parameters are: \n\tMode: ${mode} \n\tAzure Resource Group ID : ${resource_group_id} \n\tAzure APP Role : ${app_role} \n\tAzure APP Name : ${app_name}" ${debug_level}
	#The resource group is needed in configuration mode.
	if [ -z "${resource_group_id}" ]; then
		log "Please enter Azure resource id." ${error_level}
		help
		exit 1
	else
		createNewAPP
	fi
else
	log "Please specify mode." ${error_level}
	help
	exit 1
fi