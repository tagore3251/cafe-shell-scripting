#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/cafe-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

sudo yum update -y &>>$LOG_FILE_NAME
VALIDATE $? "Update the System"

sudo yum install httpd -y &>>$LOG_FILE_NAME
VALIDATE $? "Install Apache (httpd)"

sudo systemctl enable httpd &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Apache Server"

sudo systemctl start httpd &>>$LOG_FILE_NAME
VALIDATE $? "Starting Apache server"

sudo yum install mariadb-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Install MariaDB (MySQL)"

sudo systemctl enable mariadb &>>$LOG_FILE_NAME
VALIDATE $? "Enabling MariaDB Server"

sudo systemctl start mariadb &>>$LOG_FILE_NAME
VALIDATE $? "Starting MariaDB server"

sudo yum install php php-mysqlnd -y &>>$LOG_FILE_NAME
VALIDATE $? "Install PHP"

sudo systemctl restart httpd &>>$LOG_FILE_NAME
VALIDATE $? "Restart Apache to Apply Changes"

ln -s /var/www/ /home/ec2-user/environment

cd /home/ec2-user/environment
rm -rf /home/ec2-user/environment/*

wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/03-lab-mod5-challenge-EC2/s3/setup.zip &>>$LOG_FILE_NAME
VALIDATE $? "download the setup file"

unzip setup.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip setup"

wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/03-lab-mod5-challenge-EC2/s3/db.zip &>>$LOG_FILE_NAME
VALIDATE $? "download the db file"

unzip db.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip db"

wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/03-lab-mod5-challenge-EC2/s3/cafe.zip &>>$LOG_FILE_NAME
VALIDATE $? "download the cafe file"

unzip cafe.zip -d /var/www/html/ &>>$LOG_FILE_NAME
VALIDATE $? "unzip cafe"

cd /var/www/html/cafe/

wget https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.zip &>>$LOG_FILE_NAME
VALIDATE $? "download the aws file"

wget https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.phar &>>$LOG_FILE_NAME
VALIDATE $? "download the aws.phar file" 

unzip aws -d /var/www/html/cafe/ &>>$LOG_FILE_NAME
VALIDATE $? "unzip aws"


sudo chmod -R +r /var/www/html/cafe/

cd
cd /home/ec2-user/environment/setup/

./set-app-parameters.sh &>>$LOG_FILE_NAME
VALIDATE $? "Execute parameters.sh"

cd ..

cd db/
./set-root-password.sh./create-db.sh &>>$LOG_FILE_NAME
VALIDATE $? "Execute create-db.sh"

sudo sed -i "2i date.timezone = \"America/New_York\" " /etc/php.ini &>>$LOG_FILE_NAME
VALIDATE $? "Time Set"

sudo service httpd restart &>>$LOG_FILE_NAME
VALIDATE $? "Restart httpd"