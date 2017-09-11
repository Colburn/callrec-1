#!/bin/bash 

#===============================================================================
#
#          FILE:  change_community_string.sh
# 
#         USAGE:  ./change_community_string.sh 
# 
#   DESCRIPTION:  Replaces old community string with new community string. For
#                 CallREC server SNMP and Nagios Configurations.  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Cameron Hayden (CH), cameron.hayden@zoomint.com
#       COMPANY: Zoom International, Prague
#       CREATED: 02.06.2016 13:00:00 CET
#      REVISION:  ---
#===============================================================================

echo -n "Enter the community string you would like to replace (don't use 'callrec'): "

read old

echo -n "Enter the community string you would like to use: " 

read new

COUNTER=0
comm=0
snmp_comm=0
f='/opt/callrec/monitoring/default'
f2='/opt/callrec/monitoring/generate_nagios_services'


func() {

  sed -i "s/$old/\$_HOSTSNMPCOMMUNITY\$/g" $f/etc/nagios/zoom/commands_callrec.cfg
  sed -i 's/check_snmp -H $HOSTADDRESS$ /check_snmp -C $_HOSTSNMPCOMMUNITY$ -H $HOSTADDRESS$ /g' $f/etc/nagios/zoom/commands_callrec.cfg $f/etc/nagios/zoom/commands.cfg 
  sed -i 's/check_snmp!-o /check_snmp! -C $_HOSTSNMPCOMMUNITY$ -o /g' $f/etc/nagios/zoom/services/redlines.cfg  
  for i in `ls $f/etc/snmp/snmp*`; do
    sed -i "s/$old/$new/g" $i
  done 
#  grep -rl $old $f/etc/snmp/* | xargs sed -i "s/$old/$new/g"
  

  snmp_comm=`grep -rl _SNMPCOMMUNITY $f2`
  
  if (( "${#snmp_comm}" == "0" ))
  then
    sed -i "s/use        callrec-host/use        callrec-host\n    _SNMPCOMMUNITY $new/g" $f2
  else 
    sed -i "s/_SNMPCOMMUNITY $old/_SNMPCOMMUNITY $new/g" $f2
  fi

}
func
   
  comm=`grep -rl $old /etc/nagios/*`
  comm2=`grep -rl $old /etc/snmp*`
  
  if (( "${#comm}" != "0" || "${#comm2}" != "0" )); then

    for i in `ls /etc/nagios/zoom/host*`; do
 
      f=''
      f2='/etc/nagios/zoom/host*/host.cfg'
      func 
    done

  fi

restart_services() {
  echo -n "Would you like to restart the Nagios and SNMP services? [y/N]: "
  read rstrt

  if [ "$rstrt" == "Y" ] || [ "$rstrt" == "y" ]; then
     /etc/init.d/snmpd restart
     /etc/init.d/nagios restart
  elif [ "$rstrt" == "N" ] || [ "$rstrt" == "n" ]; then
    exit 0 
  else
    echo -n "Invalid Option: You must choose either 'Y' or 'N'"
    restart_services
  fi
}
restart_services
