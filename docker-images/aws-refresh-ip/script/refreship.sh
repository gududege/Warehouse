#!/bin/bash
#AWS parameters
access_key=""
access_secert=""
region=""
instance_ids=""
instance_name=""
domain_name=""
default_profile="refresh_ip"
ipv6_test_url="6.ipw.cn"
domain_ip_list=""
#script environment
ipv4=false
ipv6=false
bark_server=""
cycle_time=15
debug_level=4
info_level=3
warn_level=2
error_level=1
log_level=${info_level}
notice_level=${warn_level}
ignore_error=false
# The first parameter is log message.
# The second parameter is log level.
log() {
	local level=$([ -z "$2" ] && echo ${info_level} || echo $2)
	# log to stdout
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
		echo -e "$(date "+%m-%d %H:%M:%S") ${log_level_txt} $([ -z "${instance_name}" ] &&  echo "" || echo ${instance_name}) $1"
	fi
	# send message to bark app
	if [ -n "${bark_server}" ] && [ ${notice_level} -ge ${level} ]; then
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
		notice_bark ${bark_server} "AWS" "$(date "+%m-%d %H:%M:%S") ${log_level_txt} $([ -z "${instance_name}" ] &&  echo "" || echo ${instance_name}) $1"
	fi
}
# The first parameter is bark server url.
# The second parameter is group name.
# The third parameter is message body
notice_bark(){
   curl -s -X POST "$1" \
   -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8' \
   -d "title=$2&body=$3&group=$2&isArchive=1" >> /dev/null
}
# The first parameter is an element.
# The second parameter is an arrray which should be formatted as a string, like ${arr[*]}
isExistInArr() {
	if [ -z "$1" ] || [ -z "$2" ]; then return 1; fi
	element=$1
	arr=($(echo $* | cut -d " " -f 2-))
	for x in ${arr[*]}; do
		if [[ "${element}" == "${x}" ]]; then
			return 0
		fi
	done
	return 1
}
# Restart VM to get new IP address.
refreship() {
	local state=""
	# At first deallocate target VM
	state=$(aws ec2 stop-instances --instance-ids ${instance_ids} --profile ${default_profile} --query "StoppingInstances[*].CurrentState.Name" --output text)
	log "State changed, the VM is ${state}." ${warn_level}
	# Wait for EC2 VM stopped
	aws ec2 wait instance-stopped --instance-ids ${instance_ids} --profile ${default_profile}
	log "State changed, the VM is stopped." ${warn_level}
	# Then startup VM again
	state=$(aws ec2 start-instances --instance-ids ${instance_ids} --profile ${default_profile} --query "StartingInstances[*].CurrentState.Name" --output text)
	log "State changed, the VM is ${state}." ${warn_level}
	# Wait for EC2 VM started
	aws ec2 wait instance-running --instance-ids ${instance_ids} --profile ${default_profile}
	log "State changed, the VM is started." ${warn_level}
	# Finally, get new IP address
	getPublicIPFromProvider
}
# Configure given credential
configureAWS() {
	if aws configure set aws_access_key_id ${access_key} --profile ${default_profile} && aws configure set aws_secret_access_key ${access_secert} --profile ${default_profile} && aws configure set region ${region} --profile ${default_profile} && aws configure set output json --profile ${default_profile}; then
		log "Configure AWS CLI successfully." ${debug_level}
	else
		log "The login information is invaild." ${error_level}
		return 1
	fi
}
# Check whether given VM instance exist and is running now
checkInstanceExist() {
	if aws ec2 wait instance-exists --instance-ids ${instance_ids} --profile ${default_profile}; then
		instance_name=$(aws ec2 describe-instances --instance-ids ${instance_ids} --profile ${default_profile}  --query "Reservations[0].Instances[0].Tags[?Key=='Name'].Value" --output text)
		log "The instance exist." ${debug_level}
		return 0
	else
		log "The access key or instance id is incorrect." ${error_level}
		return 1
	fi
}
checkInstanceRunning(){
	[ "$(aws ec2 describe-instance-status --instance-id ${instance_ids} --profile ${default_profile} --query "InstanceStatuses[*].InstanceState.Name" --output text)" != "running" ] && log "The instance is not running." ${error_level} && return 1
	return 0
}
# Get public IP from VM provider
getPublicIPFromProvider() {
	if result=$(aws ec2 describe-instances --instance-ids ${instance_ids} --profile ${default_profile} --query "Reservations[0].Instances[0].{ipv4: PublicIpAddress, ipv6: Ipv6Address}"); then
		domain_ip_list=($(echo ${result} | jq $(echo "$(${ipv4} && echo ".ipv4" || echo "")$(${ipv4} && ${ipv6} && echo "," || echo "")$(${ipv6} && echo ".ipv6" || echo "")") | tr "\n" " " | tr -d "\""))
		log "The VM IP Address get from AWS is ${domain_ip_list[*]}" ${info_level}
	else
		log "The VM is not started or VM id is not correct." ${error_level}
		return 1
	fi
}
# Check whether the DNS record route to correct IP.
verifyDNSRecord() {
	local dns_ip_list=($(dig +time=3 +tries=3 +short $(echo "$(${ipv4} && echo "${domain_name} A " || echo "")$(${ipv6} && echo "${domain_name} AAAA" || echo "")") | tr "\n" " "))
	if [[ -z "${domain_ip_list[*]}" ]]; then
		log "Cannot get DNS record from network." ${error_level}
		return 1
	else
		log "The domain_name IP Address get from DNS is ${dns_ip_list[*]}" ${debug_level}
		for domain_ip in ${domain_ip_list[*]}; do
			if isExistInArr ${domain_ip} ${dns_ip_list[*]}; then
				continue
			else
				log "The DNS providers doesn't give correct IP address: ${dns_ip}" ${error_level}
				return 1
			fi
		done
	fi
	return 0
}
# Check whether current station can connect remote VM.
connectToVM() {
	# Check IPV6 support
	if curl -s ${ipv6_test_url} >>/dev/null; then
		ipv6_vaild=true
	else
		log "Current host doesn't support IPV6" ${warn_level} && ipv6_vaild=false
	fi
	# ping test
	if ${ipv4}; then
		ping -c 4 -q -W 1 -4 ${domain_name} >>/dev/null
		[ $? -ne 0 ] && log "The VM cannot be connected via IPV4" ${warn_level} && return 4
		log "The VM can be connected via IPV4" ${info_level}
	fi
	if ${ipv6} &&${ipv6_vaild};	then
		ping -c 4 -q -W 1 -6 ${domain_name} >>/dev/null
		[ $? -ne 0 ] && log "The VM cannot be connected via IPV6" ${warn_level} && return 6
		log "The VM can be connected via IPV6" ${info_level}
	fi
	return 0
}
monitor() {
	while true; do
		# If the AWS credential or VM doesn't exist, then stop this script.
		if configureAWS && checkInstanceExist; then
			# If the VM state or DNS have something wrong, then suspended current checking process.
			if checkInstanceRunning && getPublicIPFromProvider && verifyDNSRecord; then
				connectToVM
				if [ $? -eq 0 ]; then
					echo "" >>/dev/null
				elif [ $? -eq 4 ]; then
					refreship
				elif [ $? -eq 6 ]; then
					echo "" >>/dev/null
				fi
			fi
		else
			# Ignore error, try to check VM after ${cycle_time} time
			${ignore_error} || return 1
		fi
		if [ ${cycle_time} -eq 0 ]; then
			break
		else
			log "Wait ${cycle_time} minutes for next check process." ${debug_level}
			sleep "${cycle_time}m"
		fi
	done
}
help() {
	echo -e "Usage: \n\t-k\tAWS Access Key ID\n\t-s\tAWS Access Key Sercert\n\t-r\tAWS Region\n\t-i\tAWS VM Instance ID\n\t-d\tDomain name\n\t-4\tEnable IPV4\n\t-6\tEnable IPV6\n\t-u\tIPV6 test url (default: 6.ipw.cn)\n\t-c\tMonitor cycle time\n\t-n\tlog level={debug,info,warning,error}\n\t-b\tbark url=Bark server url\n\t-l\tnotice level={debug,info,warning,error}\n\t-h\thelp"
}
# Get arguments from CLI
while getopts "k:s:r:i:d:b:n:46l:c:u:hq" opts; do
	case ${opts} in
	k)
		access_key=${OPTARG}
		;;
	s)
		access_secert=${OPTARG}
		;;
	r)
		region=${OPTARG}
		;;
	i)
		instance_ids=${OPTARG}
		;;
	d)
		domain_name=${OPTARG}
		;;
	b)
		bark_server=${OPTARG}
		;;
	4)
		ipv4=true
		;;
	6)
		ipv6=true
		;;
	u)
		ipv6_test_url=${OPTARG}
		;;
	q)
		ignore_error=true
		;;
	c)
		let cycle_time=${OPTARG}
		;;
	n)
		case ${OPTARG} in
		debug)
			notice_level=${debug_level}
			;;
		warning)
			notice_level=${warn_level}
			;;
		error)
			notice_level=${error_level}
			;;
		*)
			notice_level=${info_level}
			;;
		esac
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
# Check all options are provided.
# log all needed parameters for debugging use.
log "Main parameters are: \n\tAWS Access Key ID: ${access_key} \n\tAWS Access Key Sercert: ${access_secert} \n\tAWS Region: ${region} \n\tAWS VM Instance ID: ${instance_ids} \n\tDomain name: ${domain_name} \n\tEnable IPV4: ${ipv4} \n\tEnable IPV6: ${ipv6}" ${debug_level}
if [ -z "${access_key}" ] || [ -z "${access_secert}" ] || [ -z "${region}" ] || [ -z "${instance_ids}" ] || [ -z "${domain_name}" ] || $(! ${ipv4} && ! ${ipv6}); then
	log "Please enter enough parameters." ${error_level}
	help
	exit 1
else
	monitor
fi