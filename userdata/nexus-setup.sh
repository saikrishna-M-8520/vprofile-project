#!/bin/bash

# Install Java 11 (Amazon Corretto)
amazon-linux-extras enable corretto11
yum install java-11-amazon-corretto -y   

# Create necessary directories for Nexus
mkdir -p /opt/nexus/   
mkdir -p /tmp/nexus/                           

# Download and extract Nexus
cd /tmp/nexus
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"
wget $NEXUSURL -O nexus.tar.gz
EXTOUT=`tar xzvf nexus.tar.gz`
NEXUSDIR=`echo $EXTOUT | cut -d '/' -f1`
rm -rf /tmp/nexus/nexus.tar.gz

# Sync Nexus files to the target directory
rsync -avzh /tmp/nexus/ /opt/nexus/

# Create Nexus user and set permissions
useradd nexus
chown -R nexus.nexus /opt/nexus 

# Create Nexus service file for systemd
cat <<EOT>> /etc/systemd/system/nexus.service
[Unit]                                                                          
Description=nexus service                                                       
After=network.target                                                            
                                                                  
[Service]                                                                       
Type=forking                                                                    
LimitNOFILE=65536                                                               
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start                                  
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop                                    
User=nexus                                                                      
Restart=on-abort                                                                
                                                                  
[Install]                                                                       
WantedBy=multi-user.target                                                      

EOT

# Configure Nexus to run as the Nexus user
echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc

# Reload systemd, start and enable the Nexus service
systemctl daemon-reload
systemctl start nexus
systemctl enable nexus
