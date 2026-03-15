#!/bin/bash
#!/bin/bash
yum update -y
yum install mariadb105 -y
until mysqladmin ping -h ${aws_db_instance.my_db.address} -u arya -p${var.db_password} --silent 2>/dev/null; do
  echo "DB not ready yet, retrying in 10s..."
  sleep 10
done
echo "Database is up."

mysql -h ${aws_db_instance.my_db.address} -u arya -p${var.db_password} <<MYSQL
CREATE DATABASE IF NOT EXISTS studentapp;
USE studentapp;
CREATE TABLE IF NOT EXISTS students(
student_id INT NOT NULL AUTO_INCREMENT,
student_name VARCHAR(100) NOT NULL,
student_addr VARCHAR(100) NOT NULL,
student_age VARCHAR(3) NOT NULL,
student_qual VARCHAR(20) NOT NULL,
student_percent VARCHAR(10) NOT NULL,
student_year_passed VARCHAR(10) NOT NULL,
PRIMARY KEY (student_id)
);
MYSQL