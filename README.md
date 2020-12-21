### oracle  自动化巡检脚本

#### 脚本使用前注意事项

> 需要使用oracle用户执行
> 下载脚本：https://github.com/domdanrtsey/orawatch.git

1. 使用说明（**一定切记待巡检实例名的system用户的密码必须与对应实例名匹配**）

   ```shell
   1)、多实例下运行此脚本：
   声明实例名；执行时跟上此实例对应的 system 密码
   $ export ORACLE_SID=orcl
   $ chmod +x orawatch.sh
   $ ./orawatch.sh system/yourpassword
   或者是将此实例对应的 system 密码填写到脚本中，随后执行
   $ vi orawatch.sh
   sqlstr="system/system"
   $ chmod +x orawatch.sh
   $ ./orawatch.sh
   
   2)、请注意一定要将对应实例名的对应system密码填写至脚本如下位置，或是执行时跟上对应实例的system密码，否则将造成 system 用户因密码错误而被锁定
   
   system用户解锁语句：
   SQL> alter user system account unlock;
   ```

2. 执行完巡检之后，将在脚本所在的路径下生成html巡检结果报告，如下

   192.168.35.244os_oracle_summary.html

3. 巡检项信息如下（其他统计项可根据实际需要自行添加）

   **1)、巡检ip信息**

   **2)、数据库版本**

   **3)、是否开启归档，及归档磁盘占用率与路径信息**

   **4)、数据库memory/sga/pga信息**

   **5)、数据表空间是否自动扩展**

   **6)、数据当前分配的数据表空间使用率信息**
