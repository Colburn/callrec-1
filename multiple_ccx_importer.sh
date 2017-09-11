#!/bin/bash -xv

#===============================================================================
#
#          FILE
# 
#         USAGE: Run executable
# 
#   DESCRIPTION: Grabs users and groups FROM two seperate scorecards 
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
SERVER='10.33.64.38'
NUM=0
IGNORE_GROUP='Subber Group'
EXCLUDE=`psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupid FROM ccgroups WHERE ccgroupname='$IGNORE_GROUP';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
DB=1
WEBXML='/opt/callrec/web/webapps/qm/WEB-INF/web.xml'

#Create arrays to contain necessary postgres information for users not in EXCLUDE group. 
for i in `psql -U postgres callrec -h $SERVER -t -c "SELECT userid FROM sc_users WHERE userid not in (SELECT userid FROM user_belongsto_ccgroup WHERE ccgroupid='$EXCLUDE') and login!='ipccimporterdaemon' and database=$DB;" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`; do
  #User information
  USERID[NUM]=$i
  NAME[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT name FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v name | sed -e 's/^[[:space:]]*//'`
  SURNAME[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT surname FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v surname | sed -e 's/^[[:space:]]*//'`
  LOGIN[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT login FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v login | sed -e 's/^[[:space:]]*//'`
  DATABASE[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT database FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  STATUS[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT status FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v status | sed -e 's/^[[:space:]]*//'`
  SYNC[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT sync FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v sync | sed -e 's/^[[:space:]]*//'`
  PHONE[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT phone FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  AGENTID[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT agentid FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v agentid | sed -e 's/^[[:space:]]*//'`
  INDENTIFICATOR_USED[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT identificator_used FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v identificator_used | sed -e 's/^[[:space:]]*//'`
  EMAIL[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT email FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [[:alnum:]] | grep -v email | sed -e 's/^[[:space:]]*//'`
  LANGUAGE[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT language FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [0-9[0-9]* | grep -v language | grep -v '-' | sed -e 's/^[[:space:]]*//'`
  COMPANY[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT company FROM sc_users WHERE userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'` 
  
  #Group information
  CCGROUPID[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupid FROM user_belongsto_ccgroup WHERE userid='${USERID[$NUM]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  CCGROUPNAME[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupname FROM ccgroups WHERE ccgroupid='${CCGROUPID[$NUM]}';" | grep [[:alnum:]] | grep -v ccgroupname | sed -e 's/^[[:space:]]*//'`
  CCGROUPDESCRIPTION[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT description FROM ccgroups WHERE ccgroupid='${CCGROUPID[$NUM]}';" | grep [[:alnum:]] | grep -v description | sed -e 's/^[[:space:]]*//'`
  CCGROUPCOMPANY[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT company FROM ccgroups WHERE ccgroupid='${CCGROUPID[$NUM]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`

  #Parent Group information
  CCGROUPPARENTNAME[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupname FROM ccgroups WHERE ccgroupid in (SELECT parentid FROM ccgroups WHERE ccgroupname='${CCGROUPNAME[$NUM]}');" | grep [[:alnum:]] | grep -v ccgroupname | sed -e 's/^[[:space:]]*//'`
  CCGROUPPARENTDESCRIPTION[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT description FROM ccgroups WHERE ccgroupname='${CCGROUPPARENTNAME[$NUM]}';" | grep [[:alnum:]] | grep -v description | sed -e 's/^[[:space:]]*//'`
  CCGROUPPARENTCOMPANY[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT company FROM ccgroups WHERE ccgroupname='${CCGROUPPARENTNAME[$NUM]}';" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
  CCGROUPPARENTPARENTNAME[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupname FROM ccgroups WHERE ccgroupid in (SELECT parentid FROM ccgroups WHERE ccgroupname='${CCGROUPPARENTNAME[$NUM]}');" | grep [[:alnum:]] | grep -v row | grep -v ccgroupname | sed -e 's/^[[:space:]]*//'`
 
  #Role information
  USERROLENAME[NUM]=`psql -U postgres callrec -h $SERVER -t -c "select name from wbsc.roles where roleid in (select roleid from wbsc.user_role where userid=${USERID[$NUM]});" | grep [[:alnum:]] | grep -v name | sed -e 's/^[[:space:]]*//'`
  USERROLEDESCRIPTION[NUM]=`psql -U postgres callrec -h $SERVER -t -c "select description from wbsc.roles where name='${USERROLENAME[$NUM]}';" | grep [[:alnum:]] | grep -v description | sed -e 's/^[[:space:]]*//'`
  USERROLECOMPANY[NUM]=`psql -U postgres callrec -h $SERVER -t -c "SELECT company FROM wbsc.roles WHERE name='${USERROLENAME[$NUM]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  ((NUM++))
done;

NUM2=$((NUM - 1)) 

function belongs {
  GROUPID=`psql -U postgres callrec -t -c "SELECT ccgroupid FROM ccgroups WHERE ccgroupname='${CCGROUPNAME[$1]}';"  | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  BELONGS_TO=`psql -U postgres callrec -t -c "SELECT userid FROM user_belongsto_ccgroup WHERE userid in (SELECT userid from sc_users where userid='$TEMPUSERID');" | grep [0-9][0-9]* | grep -v row | sed -e 's/^[[:space:]]*//'`
  if [ "$BELONGS_TO" == "$TEMPUSERID" ]; then
    psql -U postgres callrec -c "DELETE FROM user_belongsto_ccgroup WHERE userid=$TEMPUSERID;"
    psql -U postgres callrec -c "INSERT into user_belongsto_ccgroup(userid, ccgroupid) VALUES ($TEMPUSERID, $GROUPID);"
    psql -U postgres callrec -c "DELETE FROM user_canevaluate_ccgroup WHERE userid=$TEMPUSERID;"    
       for i in `psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupid FROM user_canevaluate_ccgroup WHERE userid=${USERID[$1]};" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`; do
         CANEVALUATEGROUPNAME=`psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupname FROM ccgroups where ccgroupid=$i;" | grep [[:alnum:]]| sed -e 's/^[[:space:]]*//'`
         CANEVALUATELOCALID=`psql -U postgres callrec -t -c "SELECT ccgroupid from ccgroups where ccgroupname='$CANEVALUATEGROUPNAME';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'` 
         psql -U postgres callrec -c "INSERT into user_canevaluate_ccgroup(userid, ccgroupid) VALUES ($TEMPUSERID, $CANEVALUATELOCALID);" 
       done
   elif [ "$BELONGS_TO" == "" ]; then
      psql -U postgres callrec -c "INSERT into user_belongsto_ccgroup(userid, ccgroupid) VALUES ($TEMPUSERID, $GROUPID);"
      psql -U postgres callrec -c "DELETE FROM user_canevaluate_ccgroup WHERE userid=$TEMPUSERID;"
        for i in `psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupid FROM user_canevaluate_ccgroup WHERE userid=${USERID[$1]};" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`; do
          CANEVALUATEGROUPNAME=`psql -U postgres callrec -h $SERVER -t -c "SELECT ccgroupname from ccgroups where ccgroupid=$i;" | grep [[:alnum:]] | sed -e 's/^[[:space:]]*//'`
          CANEVALUATELOCALID=`psql -U postgres callrec -t -c "SELECT ccgroupid from ccgroups where ccgroupname='$CANEVALUATEGROUPNAME';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
          psql -U postgres callrec -c "INSERT into user_canevaluate_ccgroup(userid, ccgroupid) VALUES ($TEMPUSERID, $CANEVALUATELOCALID);" 
        done
  fi
}
function user_roles {
  ROLEID=`psql -U postgres callrec -t -c "select roleid from wbsc.roles where name='$ROLENAME';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  USERROLE=`psql -U postgres callrec -t -c "select userid from wbsc.user_role where userid=$TEMPUSERID;"  | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
    if [ "$USERROLE" == "$TEMPUSERID" ]; then
    psql -U postgres callrec -c "DELETE FROM wbsc.user_role WHERE userid=$TEMPUSERID;"
    psql -U postgres callrec -c "INSERT into wbsc.user_role(userid, roleid) VALUES ($TEMPUSERID, $ROLEID);"
  elif [ "$USERROLE" == "" ]; then
    psql -U postgres callrec -c "INSERT into wbsc.user_role(userid, roleid) VALUES ($TEMPUSERID, $ROLEID);"
  fi
}
function import {
    TEMPUSERID=`psql -U postgres callrec -t -c "SELECT userid FROM sc_users WHERE login='${LOGIN[$1]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
    if [ "$GROUPNAME" = "" ]; then
      if [ "$PARENTID" == "" ]; then 
        psql -U postgres callrec -c "INSERT into ccgroups(ccgroupname, description, parentid, company) VALUES ('${CCGROUPPARENTNAME[$1]}', '${CCGROUPPARENTDESCRIPTION[$1]}', $PARENTPARENTID, ${CCGROUPPARENTCOMPANY[$1]});"
        PARENTID=`psql -U postgres callrec -t -c "SELECT ccgroupid FROM ccgroups WHERE ccgroupname='${CCGROUPPARENTNAME[$1]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
        psql -U postgres callrec -c "INSERT into ccgroups(ccgroupname, description, parentid, company) VALUES ('${CCGROUPNAME[$1]}', '${CCGROUPDESCRIPTION[$1]}', $PARENTID, ${CCGROUPCOMPANY[$1]});"
        #psql -U postgres callrec -c "UPDATE ccgroups set parentid='$PARENTID' WHERE ccgroupname='${CCGROUPNAME[$1]}';"
        belongs "$1"
      else
        psql -U postgres callrec -c "INSERT into ccgroups(ccgroupname, description, parentid, company) VALUES ('${CCGROUPNAME[$1]}', '${CCGROUPDESCRIPTION[$1]}', $PARENTID, ${CCGROUPCOMPANY[$1]});"
        #psql -U postgres callrec -c "UPDATE ccgroups set parentid='$PARENTID' WHERE ccgroupname='${CCGROUPNAME[$1]}';" 
        belongs "$1"
      fi
    elif [ "$GROUPNAME" == "${CCGROUPNAME[$1]}" ]; then
      if [ "$PARENTID" == "" ] && [ "$GROUPNAME" != "Root group" ]; then
        psql -U postgres callrec -c "INSERT into ccgroups(ccgroupname, description, parentid, company) VALUES ('${CCGROUPPARENTNAME[$1]}', '${CCGROUPPARENTDESCRIPTION[$1]}', $PARENTPARENTID, ${CCGROUPPARENTCOMPANY[$1]}';"
        PARENTID=`psql -U postgres callrec -t -c "SELECT ccgroupid FROM ccgroups WHERE ccgroupname='${CCGROUPPARENTNAME[$1]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
        psql -U postgres callrec -c "UPDATE ccgroups set description='${CCGROUPDESCRIPTION[$1]}', parentid='$PARENTID', company='${CCGROUPCOMPANY[$1]}' WHERE ccgroupname='${CCGROUPNAME[$1]}';"
        belongs "$1"
      elif [ "$PARENTID" == "" ] && [ "$GROUPNAME" == "Root group" ]; then 
        belongs "$1"
      else
        psql -U postgres callrec -c "UPDATE ccgroups set description='${CCGROUPDESCRIPTION[$1]}', parentid='$PARENTID', company='${CCGROUPCOMPANY[$1]}' WHERE ccgroupname='${CCGROUPNAME[$1]}';"
        belongs "$1"
     fi
   fi
}

for i in $(seq 0 $NUM2); do
  USERNAME=`psql -U postgres callrec -t -c "SELECT login FROM sc_users WHERE login='${LOGIN[$i]}';" | grep [[:alnum:]] | grep -v login | sed -e 's/^[[:space:]]*//'`
  GROUPNAME=`psql -U postgres callrec -t -c "SELECT ccgroupname FROM ccgroups WHERE ccgroupname='${CCGROUPNAME[$i]}';" | grep [[:alnum:]] | grep -v ccgroupname | sed -e 's/^[[:space:]]*//'` 
  PARENTID=`psql -U postgres callrec -t -c "SELECT ccgroupid FROM ccgroups WHERE ccgroupname='${CCGROUPPARENTNAME[$i]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  PARENTPARENTID=`psql -U postgres callrec -t -c "SELECT ccgroupid FROM ccgroups WHERE ccgroupname='${CCGROUPPARENTPARENTNAME[$i]}';" | grep [0-9][0-9]* | sed -e 's/^[[:space:]]*//'`
  ROLENAME=`psql -U postgres callrec -t -c "SELECT name from wbsc.roles where name='${USERROLENAME[$i]}';" | grep [[:alnum:]] | grep -v name | sed -e 's/^[[:space:]]*//'`
  if [ "$USERNAME" == "" ]; then
    psql -U postgres callrec -c "INSERT into sc_users(name, surname, login, database, status, identificator_used, email, language, company)
    VALUES 
    ('${NAME[$i]}', '${SURNAME[$i]}', '${LOGIN[$i]}', ${DATABASE[$i]}, '${STATUS[$i]}', '${INDENTIFICATOR_USED[$i]}', '${EMAIL[$i]}', ${LANGUAGE[$i]}, ${COMPANY[$i]});" 
    psql -U postgres callrec -c "UPDATE sc_users set phone='${PHONE[$i]}', agentid='${AGENTID[$i]}' where login='${LOGIN[$i]}';"
    import "$i"
    user_roles 
  elif [ "$USERNAME" == "${LOGIN[$i]}" ]; then
    SYNC=`psql -U postgres callrec -t -c "SELECT sync FROM sc_users WHERE login='$USERNAME';" | grep [[:alnum:]] | grep -v login | sed -e 's/^[[:space:]]*//'`
    if [ "$SYNC" == "t" ]; then
      psql -U postgres callrec -c "UPDATE sc_users set name='${NAME[$i]}', surname='${SURNAME[$i]}', login='${LOGIN[$i]}', database=${DATABASE[$i]}, status='${STATUS[$i]}', phone='${PHONE[$i]}', agentid='${AGENTID[$i]}', identificator_used='${INDENTIFICATOR_USED[$i]}', email='${EMAIL[$i]}', language='${LANGUAGE[$i]}', company=${COMPANY[$i]} WHERE login='${LOGIN[$i]}';"
      import "$i"
      user_roles 
    fi
  fi
done
touch $WEBXML
