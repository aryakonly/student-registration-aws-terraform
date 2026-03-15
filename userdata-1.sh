#!/bin/bash
yum install java -y
curl -O https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.115/bin/apache-tomcat-9.0.115.tar.gz
tar -xzvf apache-tomcat-9.0.115.tar.gz -C /opt
/opt/apache-tomcat-9.0.115/bin/./catalina.sh start
cd /opt/apache-tomcat-9.0.115/webapps/
curl -O https://s3-us-west-2.amazonaws.com/studentapi-cit/student.war
cd /opt/apache-tomcat-9.0.115/lib/
curl -O https://s3-us-west-2.amazonaws.com/studentapi-cit/mysql-connector.jar
echo "Waiting for database to accept connections..."
until mysqladmin ping -h ${aws_db_instance.my_db.address} -u arya -p${var.db_password} --silent 2>/dev/null; do
sleep 10
done
    
python3 - <<PYTHON
f = open('/opt/apache-tomcat-9.0.115/conf/context.xml', 'r')
lines = f.readlines()
f.close()

resource = '    <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxTotal="500" maxIdle="30" maxWaitMillis="1000" username="admin" password="${var.db_password}" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://${aws_db_instance.my_db.address}:3306/studentapp?useUnicode=yes&amp;characterEncoding=utf8"/>\n'

for i, line in enumerate(lines):
    if '</Context>' in line:
        lines.insert(i, resource)
        break

f = open('/opt/apache-tomcat-9.0.115/conf/context.xml', 'w')
f.writelines(lines)
f.close()
PYTHON
    
/opt/apache-tomcat-9.0.115/bin/./catalina.sh stop
/opt/apache-tomcat-9.0.115/bin/./catalina.sh start