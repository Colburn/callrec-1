#!/bin/bash -x

#===============================================================================
#
#          FILE: multiple_ccx_import.sh
# 
#         USAGE: Run executable
# 
#   DESCRIPTION: Grabs users and groups from two seperate scorecards 
#                and imports them into a single scorecard
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Cameron Hayden (CH), cameron.hayden@zoomint.com
#       COMPANY: Zoom International, Prague
#       CREATED: 04.24.2017 13:00:00 CET
#      REVISION:  ---
#===============================================================================
SERVER='10.33.64.101'
NUM=0
IGNORE_GROUP='Root group'
EXCLUDE=`psql -U postgres callrec -h $SERVER -c "select ccgroupid from ccgroups where ccgroupname='$IGNORE_GROUP';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
DB=4

#Create arrays to contain necessary postgres information for users not in EXCLUDE group. 
for i in `psql -U postgres callrec -h $SERVER -c "select userid from sc_users where userid not in (select userid from user_belongsto_ccgroup where ccgroupid='$EXCLUDE') and database=$DB;" | grep [0-9][0-9]* | grep -v row | grep -v userid`; do
  #User information
  USERID[NUM]=$i
  NAME[NUM]=`psql -U postgres callrec -h $SERVER -c "select name from sc_users where userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v name`
  SURNAME[NUM]=`psql -U postgres callrec -h $SERVER -c "select surname from sc_users where userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v surname`
  LOGIN[NUM]=`psql -U postgres callrec -h $SERVER -c "select login from sc_users where userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v login`
  DATABASE[NUM]=`psql -U postgres callrec -h $SERVER -c "select database from sc_users where userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
  SYNC[NUM]=`psql -U postgres callrec -h $SERVER -c "select sync from sc_users where userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v sync`
  PHONE[NUM]=`psql -U postgres callrec -h $SERVER -c "select phone from sc_users where userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
  AGENTID[NUM]=`psql -U postgres callrec -h $SERVER -c "select agentid from sc_users where userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v agentid`
  INDENTIFICATOR_USED[NUM]=`psql -U postgres callrec -h $SERVER -c "select indentificator_used from sc_users where userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v indentificator_used`
  EMAIL[NUM]=`psql -U postgres callrec -h $SERVER -c "select email from sc_users where userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v email`
  LANGUAGE[NUM]=`psql -U postgres callrec -h $SERVER -c "select language from sc_users where userid='${USERID[$NUM]}';" | grep [0-9[0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
  COMPANY[NUM]=`psql -U postgres callrec -h $SERVER -c "select company from sc_users where userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'` 
  
  #Group information
  CCGROUPID[NUM]=`psql -U postgres callrec -h $SERVER -c "select ccgroupid from user_belongsto_ccgroup where userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
  CCGROUPNAME[NUM]=`psql -U postgres callrec -h $SERVER -c "select ccgroupname from ccgroups where ccgroupid='${CCGROUPID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v ccgroupname`
  CCGROUPDESCRIPTION[NUM]=`psql -U postgres callrec -h $SERVER -c "select description from ccgroups where ccgroupid='${CCGROUPID[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v description`
  CCGROUPCOMPANY[NUM]=`psql -U postgres callrec -h $SERVER -c "select company from ccgroups where ccgroupid='${CCGROUPID[$NUM]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`

  #Parent Group Information
  CCGROUPPARENTNAME[NUM]=`psql -U postgres callrec -h $SERVER -c "select ccgroupname from ccgroups where ccgroupid in (select parentid from ccgroups where ccgroupname='${CCGROUPNAME[$NUM]}');" | grep [[:alnum:]] | grep -v row | grep -v ccgroupname`
  CCGROUPPARENTDESCRIPTION[NUM]=`psql -U postgres callrec -h $SERVER -c "select description from ccgroups where ccgroupid='${CCGROUPPARENTNAME[$NUM]}';" | grep [[:alnum:]] | grep -v row | grep -v description`
  CCGROUPPARENTCOMPANY[NUM]=`psql -U postgres callrec -h $SERVER -c "select company from ccgroups where ccgroupname='${CCGROUPPARENTNAME[$NUM]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
  ((NUM++))
done;

function import {
    TEMPUSERID=`psql -U postgres callrec -c "select userid from sc_users where login='${LOGIN[$i]}';"`
    if [ "$GROUPNAME" = "" ]; then
      if [ "$PARENTID" == "" ]; then 
        psql -U postgres callrec -c "INSERT into ccgroups(ccgroupname, description, company) VALUES ('${CCGROUPPARENNAME[$i]}', '${CCGROUPPARENTDESCRIPTION[$i]}, ${CCGROUPPARENTCOMPANY[$i]});"
        PARENTID=`psql -U postgres callrec -c "select ccgroupid from ccgroups where ccgroupname='${CCGROUPPARENTNAME[$i]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
        psql -U postgres callrec -c "INSERT into ccgroups(ccgroupname, description, parentid, company) VALUES ('${CCGROUPNAME[$i]}', '${CCGROUPDESCRIPTION[$i]}', '$PARENTID', '${CCGROUPCOMPANY[$i]}');"
        GROUPID=`psql -U postgres callrec -c "select ccgroupid from ccgroups where ccgroupid in (select ccgroupid from ccgroups where ccgroupname='${CCGROUPNAME[$i]}');"`
        psql -U postgres callrec -c "DELETE from user_belongsto_ccgroup where userid in (select userid from sc_users where userid='${TEMPUSERID[$i]});"
        psql -U postgres callrec -c "INSERT into user_belongsto_ccgroup(userid, groupid) VALUES ('${TEMPUSERID[$i]}', '${CCGROUPID[$i]}');"
      else
        psql -U Postgres callrec -c "INSERT into ccgroups(ccgroupname, description, parentid, company) VALUES ('${CCGROUPNAME[$i]}', '${CCGROUPDESCRIPTION[$i]}', '$PARENTID', '${CCGROUPCOMPANY[$i]}');"
        psql -U postgres callrec -c "DELETE from user_belongsto_ccgroup where userid in (select userid from sc_users where userid='${{TEMPUSERID[$i]}');"
        psql -U postgres callrec -c "INSERT into user_belongsto_ccgroup(userid, groupid) VALUES ('${TEMPUSERID[$i]}', '${CCGROUPID[$i]}');"
      fi
    elif [ "$GROUPNAME" == "${CCGROUPNAME[NUM]}" ]; then
      if [ "$PARENTID" == "" ]; then
        psql -U postgres callrec -c "INSERT into ccgroups(ccgroupname, description, company) VALUES ('${CCGROUPPARENNAME[$i]}', '${CCGROUPPARENTDESCRIPTION[$i]}', '${CCGROUPPARENTCOMPANY[$i]}');"
        PARENTID=`psql -U postgres callrec -c "select ccgroupid from ccgroups where ccgroupname='${CCGROUPPARENTNAME[$i]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
        psql -U Postgres callrec -c "UPDATE ccgroups set description='${CCGROUPDESCRIPTION[$i]}', parentid='$PARENTID', company='${CCGROUPCOMPANY[$i]}' where ccgroupname='${CCGROUPNAME[$i]}';"
        psql -U postgres callrec -c "DELETE from user_belongsto_ccgroup where userid in (select userid from sc_users where userid='${{USERID[$i]}';"
        psql -U postgres callrec -c "INSERT into user_belongsto_ccgroup(userid, groupid) VALUES ('${USERID[$i]}', '${CCGROUPID[$i]}');"
      else
        psql -U Postgres callrec -c "UPDATE ccgroups set description='${CCGROUPDESCRIPTION[$i]}', parentid='$PARENTID', company='${CCGROUPCOMPANY[$i]}' where ccgroupname='${CCGROUPNAME[$i]}';"
        psql -U postgres callrec -c "DELETE from user_belongsto_ccgroup where userid in (select userid from sc_users where userid='${{USERID[$i]}';"
        psql -U postgres callrec -c "INSERT into user_belongsto_ccgroup(userid, groupid) VALUES ('${USERID[$i]}', '${CCGROUPID[$i]}');"
     fi
   fi
}

for i in "${USERID[@]}"; do
  USERNAME=`psql -U postgres callrec -c "select login from sc_hsers where userid='${USERID[$i]}';" | grep [[:alnum:]] | grep -v row| grep -v login`
  GROUPNAME=`psql -U postgres callrec -c "select ccgroupname from ccgroups where ccgroupname='${CCGROUPNAME[$i]}';" | grep [[:alnum:]] | | grep -v row | grep -v ccgroupname` 
  PARENTID=`psql -U postgres callrec -c "select ccgroupid from ccgroups where ccgroupname='${CCGROUPPARENTNAME[$i]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`  
  if [ "$USERNAME" == "" ]; then
    psql -U postgres callrec -c "INSERT into sc_users(name, surname, login, database, sync, phone, agentid, indetificator_used, email, language, company)
    VALUES 
    ('${NAME[$i]}', '${SURNAME[$i]}', '${LOGIN[$i]}', ${DATABASE[$i]}, '${SYNC[$i]}', '${PHONE[$i]}', '${AGENTID[$i]}', '${INDEFICATOR_USED[$i]}', '${EMAIL[$i]}', '${LANGUAGE[$i]}', '${COMPANY[$i]}');" 
  import
  elif [ "$USERNAME" == "${LOGIN[$i]}" ]; then
    psql -U postgres callrec -c "UPDATE sc_users set name='${NAME[$i]}', surname='${SURNAME[$i]}', login='${LOGIN[$i]}', database='${DATABASE[$i]}', sync='${SYNC[$i]}', phone='${PHONE[$i]}', agentid='${AGENTID[$i]}', indentificator_used='${INDENTIFICATOR_USED[$i]}', email='${EMAIL[$i]}', language='${LANGUAGE[$i]}', company='${COMPANY[$i]}' where login='${LOGIN[$i]}';"
  import
  fi
done
