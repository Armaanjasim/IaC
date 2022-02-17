#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install nginx -y
sudo apt-get install nodejs -y
sudo apt-get install python-software-properties -y
curl -sl https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install nodejs -y
sudo apt-get install npm -y
sudo npm install pm2 -g
echo "export DB_HOST=mongodb://10.0.3.236:27017/posts" >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc
sudo systemctl restart nginx
sudo systemctl enable nginx