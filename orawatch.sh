#!/bin/bash
# script_name: orawatch.sh
# Author: Danrtsey.Shun
# Email:mydefiniteaim@126.com
# usage:
# chmod +x orawatch.sh
# export ORACLE_SID=orcl
# ./orawatch.sh system/yourpassword
ipaddress=`ip a|grep "global"|awk '{print $2}' |awk -F/ '{print $1}'`
file_output=${ipaddress}'os_oracle_summary.html'
td_str=''
th_str=''
sqlstr=$1
test $1
if [ $? = 1 ]; then
 echo
 echo "Info...You did not enter a value for sqlstr."
 echo "Info...Using default value = system/system"
 sqlstr="system/system"
fi
export NLS_LANG='american_america.AL32UTF8'
#yum -y install bc sysstat net-tools
create_html_css(){
  echo -e "<html>
<head>
<style type="text/css">
    body        {font:12px Courier New,Helvetica,sansserif; color:black; background:White;}
    table,tr,td {font:12px Courier New,Helvetica,sansserif; color:Black; background:#FFFFCC; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} 
    th          {font:bold 12px Courier New,Helvetica,sansserif; color:White; background:#0033FF; padding:0px 0px 0px 0px;} 
    h1          {font:bold 12pt Courier New,Helvetica,sansserif; color:Black; padding:0px 0px 0px 0px;} 
</style>
</head>
<body>"
}
create_html_head(){
echo -e "<h1>$1</h1>"
}
create_table_head1(){
  echo -e "<table width="68%" border="1" bordercolor="#000000" cellspacing="0px" style="border-collapse:collapse">"
}
create_table_head2(){
  echo -e "<table width="100%" border="1" bordercolor="#000000" cellspacing="0px" style="border-collapse:collapse">"
}
create_td(){
    td_str=`echo $1 | awk 'BEGIN{FS="|"}''{i=1; while(i<=NF) {print "<td>"$i"</td>";i++}}'`
}
create_th(){
    th_str=`echo $1|awk 'BEGIN{FS="|"}''{i=1; while(i<=NF) {print "<th>"$i"</th>";i++}}'`
}
create_tr1(){
  create_td "$1"
  echo -e "<tr>
    $td_str
  </tr>" >> $file_output
}
create_tr2(){
  create_th "$1"
  echo -e "<tr>
    $th_str
  </tr>" >> $file_output
}
create_tr3(){
  echo -e "<tr><td>
  <pre style=\"font-family:Courier New; word-wrap: break-word; white-space: pre-wrap; white-space: -moz-pre-wrap\" >
  `cat $1`
  </pre></td></tr>" >> $file_output
}
create_table_end(){
  echo -e "</table>"
}
create_html_end(){
  echo -e "</body></html>"
}
NAME_VAL_LEN=12
name_val () {
   printf "%+*s | %s\n" "${NAME_VAL_LEN}" "$1" "$2"
}
get_netinfo(){
   echo "interface | status | ipadds     |      mtu    |  Speed     |     Duplex" >>/tmp/tmpnet_h1_`date +%y%m%d`.txt
   for ipstr in `ifconfig -a|grep ": flags"|awk  '{print $1}'|sed 's/.$//'`
   do
      ipadds=`ifconfig ${ipstr}|grep -w inet|awk '{print $2}'`
      mtu=`ifconfig ${ipstr}|grep mtu|awk '{print $NF}'`
      speed=`ethtool ${ipstr}|grep Speed|awk -F: '{print $2}'`
      duplex=`ethtool ${ipstr}|grep Duplex|awk -F: '{print $2}'`
      echo "${ipstr}"  "up" "${ipadds}" "${mtu}" "${speed}" "${duplex}"\
      |awk '{print $1,"|", $2,"|", $3,"|", $4,"|", $5,"|", $6}'  >>/tmp/tmpnet1_`date +%y%m%d`.txt
   done
}
ora_base_info(){
  echo "######################## 1.数据库版本"
  echo "select ' ' as \"--1.Database Version\" from dual;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_base_`date +%y%m%d`.txt
  echo "Select version FROM Product_component_version Where SUBSTR(PRODUCT,1,6)='Oracle';" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_base_`date +%y%m%d`.txt
}
ora_archive_info(){
  echo "######################## 2.归档状态"
  echo "select ' ' as \"--2.DB Archive Mode\" from dual;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_archive_`date +%y%m%d`.txt
  echo "select archiver from v\$instance;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_archive_`date +%y%m%d`.txt
  sed -i '33!d' /tmp/tmpora_archive_`date +%y%m%d`.txt
  archive_string=`cat /tmp/tmpora_archive_\`date +%y%m%d\`.txt`
  if [ $archive_string = STARTED ];then
    echo "set linesize 333;
	col FILE_TYPE for a13;
    select FILE_TYPE,PERCENT_SPACE_USED as \"占用率(%)\",PERCENT_SPACE_RECLAIMABLE,NUMBER_OF_FILES,CON_ID from v\$flash_recovery_area_usage where FILE_TYPE = 'ARCHIVED LOG';
    show parameter log_archive;
	col NAME for a40;
	col 已使用空间 for a13;
	select NAME,SPACE_LIMIT/1024/1024 as \"最大空间(M)\",SPACE_USED/1024/1024 as \"已使用空间(M)\",SPACE_RECLAIMABLE,NUMBER_OF_FILES,CON_ID from v\$recovery_file_dest;" >ora_sql.sql
    sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_archive_`date +%y%m%d`.txt
	for i in `seq 2`; do sed -i '$d' /tmp/tmpora_archive_`date +%y%m%d`.txt ; done
  fi
}
ora_mem_info(){
  echo "######################## 3.1 内存参数memory"
  echo "select ' ' as \"--3.1.DB memory\" from dual;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_mem_`date +%y%m%d`.txt
  echo "set line 2500;
  show parameter memory;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_mem_`date +%y%m%d`.txt
}
ora_sga_info(){
  echo "######################## 3.2 内存参数sga"
  echo "select ' ' as \"--3.2.DB sga\" from dual;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_sga_`date +%y%m%d`.txt
  echo "set line 2500;
  show parameter sga;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_sga_`date +%y%m%d`.txt
}
ora_pga_info(){
  echo "######################## 3.3 内存参数pga"
  echo "select ' ' as \"--3.3.DB pga\" from dual;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_pga_`date +%y%m%d`.txt
  echo "set line 2500;
  show parameter pga;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_pga_`date +%y%m%d`.txt
}
ora_dbfile_info(){
  echo "######################## 4.表空间是否自动扩展"
  echo "select ' ' as \"--4.DB dbfile\" from dual;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_dbfile_`date +%y%m%d`.txt
  echo "set lines 2500;
  col TABLESPACE_NAME for a15;
  col FILE_NAME for a60;
  select FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE, maxbytes/1024/1024 as max_m,increment_by/1024/1024 as incre_m  from dba_data_files;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_dbfile_`date +%y%m%d`.txt
}
ora_dbfile_useage_info(){
  echo "######################## 5.表空间使用率"
  echo "select ' ' as \"--5.DB dbfile useage\" from dual;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_dbfile_useage_`date +%y%m%d`.txt
  echo "set line 2500;
  col 表空间名 for a14;
  SELECT UPPER(F.TABLESPACE_NAME) \"表空间名\",D.TOT_GROOTTE_MB \"表空间大小(G)\",D.TOT_GROOTTE_MB - F.TOTAL_BYTES \"已使用空间(G)\",TO_CHAR(ROUND((D.TOT_GROOTTE_MB - F.TOTAL_BYTES) / D.TOT_GROOTTE_MB * 100,2),'990.99') || '%' \"使用比\",F.TOTAL_BYTES \"空闲空间(G)\",F.MAX_BYTES \"最大块(G)\" FROM (SELECT TABLESPACE_NAME,ROUND(SUM(BYTES) / (1024 * 1024*1024), 2) TOTAL_BYTES,ROUND(MAX(BYTES) / (1024 * 1024*1024), 2) MAX_BYTES FROM SYS.DBA_FREE_SPACE   where tablespace_name<> 'USERS' GROUP BY TABLESPACE_NAME) F,(SELECT DD.TABLESPACE_NAME,ROUND(SUM(DD.BYTES) / (1024 * 1024*1024), 2) TOT_GROOTTE_MB FROM SYS.DBA_DATA_FILES DD where dd.tablespace_name<> 'USERS' GROUP BY DD.TABLESPACE_NAME) D WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME ORDER BY 1;" >ora_sql.sql
  sqlplus $sqlstr <ora_sql.sql>>/tmp/tmpora_dbfile_useage_`date +%y%m%d`.txt
}


create_html(){
  rm -rf $file_output
  touch $file_output
  create_html_css >> $file_output

  create_html_head "0 Network Info Summary" >> $file_output
  create_table_head1 >> $file_output
  get_netinfo
  while read line
  do
    create_tr2 "$line" 
  done < /tmp/tmpnet_h1_`date +%y%m%d`.txt
  while read line
  do
    create_tr1 "$line" 
  done < /tmp/tmpnet1_`date +%y%m%d`.txt
  create_table_end >> $file_output

  create_html_head "1 Version of Database" >> $file_output
  create_table_head1 >> $file_output
  ora_base_info
  sed -i '27,33!d' /tmp/tmpora_base_`date +%y%m%d`.txt
  sed -i '2,3d' /tmp/tmpora_base_`date +%y%m%d`.txt
  create_tr3 "/tmp/tmpora_base_`date +%y%m%d`.txt"
  create_table_end >> $file_output

  create_html_head "2 Status of archive_log" >> $file_output
  create_table_head1 >> $file_output
  ora_archive_info
  sed -i '2,11d' /tmp/tmpora_archive_`date +%y%m%d`.txt
  create_tr3 "/tmp/tmpora_archive_`date +%y%m%d`.txt"
  create_table_end >> $file_output

  create_html_head "3.1 memory Config of Database" >> $file_output
  create_table_head1 >> $file_output
  ora_mem_info
  sed -i '1,30d' /tmp/tmpora_mem_`date +%y%m%d`.txt
  for i in `seq 2`; do sed -i '$d' /tmp/tmpora_mem_`date +%y%m%d`.txt ; done
  create_tr3 "/tmp/tmpora_mem_`date +%y%m%d`.txt"
  create_table_end >> $file_output

  create_html_head "3.2 sga Config of Database" >> $file_output
  create_table_head1 >> $file_output
  ora_sga_info
  sed -i '1,30d' /tmp/tmpora_sga_`date +%y%m%d`.txt
  for i in `seq 2`; do sed -i '$d' /tmp/tmpora_sga_`date +%y%m%d`.txt ; done
  create_tr3 "/tmp/tmpora_sga_`date +%y%m%d`.txt"
  create_table_end >> $file_output

  create_html_head "3.3 pga Config of Database" >> $file_output
  create_table_head1 >> $file_output
  ora_pga_info
  sed -i '1,30d' /tmp/tmpora_pga_`date +%y%m%d`.txt
  for i in `seq 2`; do sed -i '$d' /tmp/tmpora_pga_`date +%y%m%d`.txt ; done
  create_tr3 "/tmp/tmpora_pga_`date +%y%m%d`.txt"
  create_table_end >> $file_output

  create_html_head "4 dbfile autoextensible of Database" >> $file_output
  create_table_head1 >> $file_output
  ora_dbfile_info
  sed -i '1,30d' /tmp/tmpora_dbfile_`date +%y%m%d`.txt
  for i in `seq 2`; do sed -i '$d' /tmp/tmpora_dbfile_`date +%y%m%d`.txt ; done
  create_tr3 "/tmp/tmpora_dbfile_`date +%y%m%d`.txt"
  create_table_end >> $file_output

  create_html_head "5 dbfile usage of Database" >> $file_output
  create_table_head1 >> $file_output
  ora_dbfile_useage_info
  sed -i '1,30d' /tmp/tmpora_dbfile_useage_`date +%y%m%d`.txt
  for i in `seq 2`; do sed -i '$d' /tmp/tmpora_dbfile_useage_`date +%y%m%d`.txt ; done
  create_tr3 "/tmp/tmpora_dbfile_useage_`date +%y%m%d`.txt"
  create_table_end >> $file_output
  
  create_html_end >> $file_output
  sed -i 's/BORDER=1/width="68%" border="1" bordercolor="#000000" cellspacing="0px" style="border-collapse:collapse"/g' $file_output
  rm -rf /tmp/tmp*_`date +%y%m%d`.txt
  rm -rf ora_sql.sql
}
PLATFORM=`uname`
if [ ${PLATFORM} = "HP-UX" ] ; then
    echo "This script does not support HP-UX platform for the time being"
exit 1
elif [ ${PLATFORM} = "SunOS" ] ; then
    echo "This script does not support SunOS platform for the time being"
exit 1
elif [ ${PLATFORM} = "AIX" ] ; then
    echo "This script does not support AIX platform for the time being"
exit 1
elif [ ${PLATFORM} = "Linux" ] ; then
  create_html
fi
