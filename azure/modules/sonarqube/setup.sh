#!/bin/bash
set -e

# Update apt cache and install prerequisites
apt-get update
apt-get install -y openjdk-17-jdk wget unzip acl postgresql postgresql-contrib

# Configure PostgreSQL
sudo -u postgres psql -c "CREATE USER sonar WITH PASSWORD 'sonarpassword';"
sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"

# Configure sysctl limits
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -w fs.file-max=65536
echo "fs.file-max=65536" >> /etc/sysctl.conf

# Create SonarQube user and group
groupadd sonar
useradd -c "SonarQube user" -g sonar -s /bin/bash sonar

# Download and extract SonarQube
SONAR_VERSION="9.9.1.69595"
wget "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip" -O "/tmp/sonarqube-${SONAR_VERSION}.zip"
unzip -o "/tmp/sonarqube-${SONAR_VERSION}.zip" -d /opt/
ln -s "/opt/sonarqube-${SONAR_VERSION}" /opt/sonarqube
chown -R sonar:sonar "/opt/sonarqube-${SONAR_VERSION}"
chown -R sonar:sonar /opt/sonarqube

# Configure SonarQube database properties
sed -i 's/^#\?sonar.jdbc.url=.*/sonar.jdbc.url=jdbc:postgresql:\/\/localhost\/sonarqube/' /opt/sonarqube/conf/sonar.properties
sed -i 's/^#\?sonar.jdbc.username=.*/sonar.jdbc.username=sonar/' /opt/sonarqube/conf/sonar.properties
sed -i 's/^#\?sonar.jdbc.password=.*/sonar.jdbc.password=sonarpassword/' /opt/sonarqube/conf/sonar.properties

# Create systemd service
cat <<EOF > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Start and enable SonarQube service
systemctl daemon-reload
systemctl enable --now sonarqube
