cd /opt/
yum install java-17-amazon-corretto -y
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.4.0.54424.zip
unzip sonarqube-9.4.0.54424.zip
useradd sonar
chown sonar:sonar sonarqube-9.4.0.54424 -R
chmod 777 sonarqube-9.4.0.54424 -R