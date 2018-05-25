#! /bin/bash
########################################################################
#                   Varibales you need to input.                      
#                          All accounts.   
#                    One account can dual twice.                             
account[0]='-a phone_num1 -p passwd1 -imsi imsi1'
account[1]='-a phone_num2 -p passwd2 -imsi imsi2'
account[2]='-a phone_num3 -p passwd3 -imsi imsi3'
#                         All interfaces.  
interface=('wan1' 'wan2' 'wan3' 'wan4')
# For me, I have 3 accounts to dual 3 times with type 0 and 1 time with
# type 1 with 3 account turn to use. In another word, I dual 4 times daily. 
# The reason why it is not 6 times is only 650h available for each account 
# monthly. It is not enough for twice_dual every day. Hope you've got it.               
#                          Config Files.                             
program='/usr/fchinanet/core '                                         
log_file='/usr/fchinanet/log'                                          
date_file='/usr/fchinanet/date'                                        
exit_file=' </usr/fchinanet/exit'                                      
########################################################################


########################################################################
#                     Other global varibales.                          
auth_count=0 # All auth count.                                         
totally_failed_count=0 # Totally failed auth count.                    
interval=('3s' '1m' '30m') # Intervals to sleep for different scences. 
online_option[0]=' -t 0 -bt' # Multi dual options.                     
online_option[1]=' -t 1 -bt'                                           
log_on=1 # Open the log with num 1 or not with 0.                      
########################################################################

# Initial And Clean Works.
handle_date(){
	[[ $1 -eq 1 ]] && return $( < $date_file)
	sleep ${interval[1]} && echo $(date +%j) > $date_file
}

initial_work(){
	write2log 1
	for (( i = 0; i < ${#interface[@]}; i++ )); do
		result[$i]=0
	done
########################################################################
# Num 7 and 3 need to be changed if there be more or less accounts.
# You'd be better read this loop for your scene.
# For me, finally, the auth_string.length is 7. 
# 3 of online_option 0 account dual daily,
# and 3 of online_option 1 turn to use.
########################################################################
	for (( i = 1; i < 7; i++ )); do
		j=0 && [[ $i > 3 ]] && j=1
		iplus1=`expr $i - 1`
		tidx=`expr $iplus1 % 3`
		auth_string[$i]=${program}${account[$tidx]}${online_option[$j]}${exit_file}
	done
	handle_date 1
	idx=`expr $? % 3 + 4`
	auth_string[0]=${auth_string[$idx]}
}

clean_work(){
	mwan3 restart 1>/dev/null 2>&1
	handle_date 0
	write2log 3 'ALL ONLINE!'
	maintain_func
}

# Network Operations.
commit_network_config(){
	uci commit network
	/etc/init.d/network reload
	sleep ${interval[0]}
}

metric_recovery(){
	for (( i = 0; i < ${#interface[@]}; i++ )); do
		uci set network.${interface[$i]}.metric=$[ i + 100 ]
	done
	commit_network_config
}

reset_network(){
	/etc/init.d/network restart && sleep ${interval[0]}
########################################################################
# The initial value of i should be consistent to your network interface configs.
########################################################################
	for (( i = 1; i < ${#interface[@]}; i++ )); do
########################################################################
# eth0.3 need to be changed according to your router devices.
# It's name of wan normally.
########################################################################
		ip link add link eth0.3 name "veth$i" type macvlan
		ifconfig "veth$i" up
	done
	metric_recovery && sleep ${interval[0]}
}

# Core Auth Process.
triple_auth(){
	uci set network.${interface[$1]}.metric=1 && commit_network_config
	for (( i = 0; i < 3; i++ )); do
		msg=`eval ${auth_string[$1]}`
		write2log 2 "[AUTH_${interface[$1]}] $msg"
		sleep ${interval[0]} && is_connected
		tresult=$?
		if [[ $tresult -eq 1 ]]; then
			for (( j = 0; j < ${#result[@]}; j++ )); do
				[[ "${interface[$1]}" == ${interface[$j]} ]] && result[$j]=1
			done
			metric_recovery && return
		fi
		sleep ${interval[0]}
	done
	metric_recovery
}

# Assistant Auth Logic.
write2log(){
	[[ $log_on -eq 0 ]] && return
	[[ $1 -eq 1 ]] && [[ -f $log_file ]] && rm -rf $log_file && return
	[[ $1 -eq 2 ]] && echo ${@:2} >> $log_file && return
	[[ $1 -eq 3 ]] && echo "---------------------${@:2}---------------------" >> $log_file
}

is_connected(){
	ping -c 3 www.qq.com > /dev/null 2>&1
	if [ $? -eq 0 ];then
    	return 1
	else
    	return 2
	fi
}

# is_connected(){
# 	timeout=2
# 	target=www.baidu.com
# ########################################################################
# # You need to confirm curl can work well on your router.
# ########################################################################
# 	ret_code=`curl -I -s --connect-timeout $timeout $target -w %{http_code} | tail -n1`
# 	if [[ "x$ret_code" = "x200" ]]; then
# 		return 1
# 	else
# 		return 2
# 	fi
# }

reboot_logic(){
	[[ $1 == 'f' ]] && reboot
	totally_failed_count=$[ totally_failed_count + 1 ]
	[[ $totally_failed_count -eq 3 ]] && reboot
}

partly_auth(){
	while [[ 0 -eq 0 ]]; do
		auth_result
		[[ $? -eq 2 ]] && clean_work
		[[ $[ auth_count - totally_failed_count ] -eq 3 ]] && reboot_logic 'f'
	done
}

user_auth(){
	auth_count=$[ auth_count + 1 ]
	write2log 3 "AUTH $auth_count PROCESS"
	for (( k = 0; k < ${#result[@]}; k++ )); do
		triple_auth $k
	done
}

auth_result(){
	reset_network && user_auth
	flag=0
	for data in ${result[@]}; do
		[[ ${data} -eq 1 ]] && flag=$[ flag + 1 ]
	done
	[[ $flag -eq 0 ]] && return 1
	[[ $flag -eq 4 ]] && return 2
	return 3
}

auth_logic(){
	auth_result
	tmp=$?
	[[ $tmp -eq 1 ]] && reboot_logic && return
	[[ $tmp -eq 2 ]] && clean_work
	[[ $tmp -eq 3 ]] && partly_auth
}

# Maintain func
maintain_func(){
	while [[ 0 -eq 0 ]]; do
		sleep ${interval[1]}
		is_connected
		[[ $? -eq 2 ]] && main_func
	done
}

# Main Func.
main_func(){
	initial_work
	while [[ "" == "" ]]; do
		auth_logic
		sleep ${interval[2]}
	done
}

main_func