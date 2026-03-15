#!/bin/bash
yum install mariadb105* -y
systemctl start mariadb.service
systemctl enable mariadb.service
mysql -h ${aws_db_instance.my_db.address} -u arya -pAryakadam47 <<MYSQL
create database studentapp;
use studentapp;
CREATE TABLE if not exists students(student_id INT NOT NULL AUTO_INCREMENT,
student_name VARCHAR(100) NOT NULL,
student_addr VARCHAR(100) NOT NULL,
student_age VARCHAR(3) NOT NULL,
student_qual VARCHAR(20) NOT NULL,
student_percent VARCHAR(10) NOT NULL,
student_year_passed VARCHAR(10) NOT NULL,
PRIMARY KEY (student_id)
);
MYSQL