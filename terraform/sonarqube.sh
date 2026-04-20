#!/bin/bash
cd /opt/
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.4.0.54424.zip
unzip sonarqube-9.4.0.54424.zip
yum install java-17-amazon-corretto -y
useradd sonar
chown sonar:sonar sonarqube-9.4.0.54424 -R
chmod 777 sonarqube-9.4.0.54424 -R
su - sonar
cd /opt/sonarqube-9.4.0.54424/bin/linux-x86-64
./sonar.sh start