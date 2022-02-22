# IAC with Ansible
![Ansible](Ansible.PNG)

## Table Of Contents

## Creating A Vagrantfile For Three VMs For Ansible architecture
### Ansible controller and Ansible agents 
```ruby

# -*- mode: ruby -*-
 # vi: set ft=ruby :
 
 # All Vagrant configuration is done below. The "2" in Vagrant.configure
 # configures the configuration version (we support older styles for
 # backwards compatibility). Please don't change it unless you know what
 
 # MULTI SERVER/VMs environment 
 #
 Vagrant.configure("2") do |config|
 # creating are Ansible controller
   config.vm.define "controller" do |controller|
     
    controller.vm.box = "bento/ubuntu-18.04"
    
    controller.vm.hostname = 'controller'
    
    controller.vm.network :private_network, ip: "192.168.33.12"
    
    # config.hostsupdater.aliases = ["development.controller"] 
    
   end 
 # creating first VM called web  
   config.vm.define "web" do |web|
     
     web.vm.box = "bento/ubuntu-18.04"
    # downloading ubuntu 18.04 image
 
     web.vm.hostname = 'web'
     # assigning host name to the VM
     
     web.vm.network :private_network, ip: "192.168.33.10"
     #   assigning private IP
     
     #config.hostsupdater.aliases = ["development.web"]
     # creating a link called development.web so we can access web page with this link instread of an IP   
         
   end
   
 # creating second VM called db
   config.vm.define "db" do |db|
     
     db.vm.box = "bento/ubuntu-18.04"
     
     db.vm.hostname = 'db'
     
     db.vm.network :private_network, ip: "192.168.33.11"
     
     #config.hostsupdater.aliases = ["development.db"]     
   end
 
 
 end
```

## Infrastructure as Code (IaC)
### Ansible & Terraform
- Configuration Management
- Orchestration
- Push Config - Ansible To Push To Config
- Terraform For Orchestration
- Ansible YAML/YML file.yml/yaml
- Ansible:
  - Simple
  - Agentless


## Run Three Virutal Machines
- `vagrant up` the vagrant file which should boot up three virutal machines. First one called `controller`, second being `web` and the last one being `db`.
- After this is done you can use `vagrant status` to see if they are all actually running
- Once they are all running `ssh` into each one of them and use the update and upgrade commands to see if they are connected to the internet `sudo apt-get update -y` and `sudo apt-get upgrade -y`

### Setting Up Ansible Controller
- Install required dependencies:
  - Python `sudo apt-get install software-properties-common`
  - Ansible `sudo apt-add-repository ppa:ansible/ansible` , `sudo apt-get install ansible -y`, `ansible --version`
  - Tree `sudo apt install tree`
- set up the agent nodes 
- default folder structures /etc/ansible/hosts
- hosts file - agent node called web IP of the web
- in /etc/ansible/hosts add
```
[web]
192.168.33.10 ansible_connection=ssh ansible_ssh_user=vagrant ansible_ssh_pass=vagrant
[db]
192.168.33.11 ansible_connection=ssh ansible_ssh_user=vagrant ansible_ssh_pass=vagrant
```
- See free storage `ansible all -a "free"`
- Copy file from one place to the other `ansible web -m copy -a "src=/etc/ansible/readme.md dest=/home/vagrant/readme.md"`
- SSH into an agent node from the ansible controller `ssh vagrant@<ip>`
  - - `ssh vagrant@192.168.33.10`, `ssh vagrant@192.168.33.11`


### Ansible Playbooks
- Playbooks used right can make automation easy, reusable and time efficent
- Playbooks can be written in yaml/yml files that implement config management
- The file should start with `---`
- To run a playbook from ansible controller go to the ansible directory `/etc/ansible` & run it by using `ansible-playbook <name>.yml`. In this same directory you can directly access the shell of a node by using `ansible <host name> -a '<command example:ls>'`

Web Playbook
```yml
---
- hosts: web
  gather_facts: yes
  become: yes
  tasks:
  -  name: syncing app folder
     synchronize:
       src: /home/vagrant/app
       dest: ~/
  -  name: load a specific version of nodejs
     shell: curl -sl https://deb.nodesource.com/setup_6.x | sudo -E bash -
  -  name: install the required packages
     apt:
       pkg:
         - nginx
         - nodejs
         - npm
       update_cache: yes
  -  name: nginx configuration for reverse proxy
     synchronize:
       src: /home/vagrant/app/default
       dest: /etc/nginx/sites-available/default
  -  name: nginx restart
     service: name=nginx state=restarted
  -  name: nginx enable
     service: name=nginx enabled=yes
  -  name: setting db variable
     lineinfile: dest=/home/vagrant/.bashrc line='export DB_HOST=mongodb://192.168.33.11:27017/posts'

```

DB Playbook
```yml
---
- hosts: db
  gather_facts: yes
  become: true
  tasks:
  -  name: installing mongodb
     apt: pkg=mongodb state=present
  -  name: synchronize mongodb conf file
     synchronize:
       src: /home/vagrant/app/mongodb.conf
       dest: /etc/
  -  name: restart mongodb
     service: name=mongodb state=restarted
  -  name: enable mongodb
     service: name=mongodb enabled=yes
```

## Anseible Controller Hybrid
- Setting up ansible controller as hybrid (prem-public)
- Install required dependencies
  - `sudo apt-get update -y && sudo apt-get upgrade -y`
  - `sudo apt-get install tree`
  - `sudo apt-add-repository --yes --update ppa:ansible/ansible`
  - `sudo apt-get install ansible -y`
  - `sudo apt-get install python3-pip`
  - `pip3 install awscli`
  - `pip3 install boto boto3`
  - To check everything is installed correctly use `aws --version`
- Create a folder in `/etc/ansible` called `group_vars` and within this folder create another one called `all` and then finally a yml file for the vault. Example of how to create a vault is `sudo ansible-vault create pass.yml`. The `pwd` command should then show you `/etc/ansible/group_vars/all/pass.yml`.
- In this file we want to add the aws credentials
```
aws_access_key: ACCESSKEY
aws_secret_key: SECRETKEY
```
- After adding the aws credentials type `sudo chmod 600 pass.yml` to give permission for the file to be read. Remember to access this vault you must use `--ask-vault-<filename>` in this case it is `--ask-vault-pass`

### Playbook For Creating an EC2 Instance
- First create a public and private key in the `.ssh` directory. Can be created by using `ssh-keygen -t rsa -b 4096`
- create ec2 yml file:
```yml
---
- hosts: localhost
  connection: local
  gather_facts: yes
  vars_files:
  - /etc/ansible/group_vars/all/pass.yml
  tasks:
  - ec2_key:
      name: eng103a
      key_material: "{{ lookup('file', '/home/vagrant/.ssh/id_rsa.pub') }}"
      region: "eu-west-1"
      aws_access_key: "{{aws_access_key}}"
      aws_secret_key: "{{aws_secret_key}}"
  - ec2:
      aws_access_key: "{{aws_access_key}}"
      aws_secret_key: "{{aws_secret_key}}"
      key_name: eng103a
      instance_type: t2.micro
      image: ami-07d8796a2b0f8d29c
      wait: yes
      group: default
      region: "eu-west-1"
      count: 1
      vpc_subnet_id: <subnet_id>
      assign_public_ip: yes
      instance_tags:
        Name: ArmaanPlayBook

```
Starting The App Playbook
```yml
---
- hosts: web
  gather_facts: yes
  become: yes
  tasks:
  -  name: starting the app
     shell:  cd app;  sudo node seeds/seed.js;  sudo npm install;  sudo screen -d -m npm start

```
- To run this playbook use this command `sudo ansible-playbook start_ec2.yml --connection=local -e "ansible_python_interpreter=/usr/bin/python3" --ask-vault-pass -v`. To avoid using `-e ansible_python_interpreter=/usr/bin/python3` you can set an alias for python. `python=python3`
- After this is done you can get the IP from amazon ec2 instance page and put it in the hosts file
```
[aws]
<ip> ansible_connection=ssh ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/home/vagrant/.ssh/id_rsa.pub
```
- After this is done you can ping to see if theres a connection by using `sudo ansible aws -m ping --ask-vault-pass`. If pong is returned you can then run the yml files you created to download nginx, node etc on the instance. Just remember to change the hosts in the yml to match aws instead of web.

## Ansible Controller On AWS
- Create an Ec2 Instance
- Follow the steps to download the dependencies until you have created the vault. [click here to get redirected to the steps](#anseible-controller-hybrid)
- Create an rsa key pair in the `/.ssh` using `ssh-keygen -t rsa -b 4096`

create instance playbook
```yml
---
- hosts: localhost
  connection: local
  gather_facts: yes
  vars_files:
  - /etc/ansible/group_vars/all/pass.yml
  vars:
    ec2_instance_name: eng103a-armaan-ansible-db
    ec2_sg_name: eng103a-armaan-vpc-db-sg
    ec2_pem_name: eng103a-armaan
  tasks:
  - ec2_key:
      name: "{{ec2_pem_name}}"
      key_material: "{{ lookup('file', '/home/ubuntu/.ssh/id_rsa.pub') }}"
      region: "eu-west-1"
      aws_access_key: "{{aws_access_key}}"
      aws_secret_key: "{{aws_secret_key}}"
  - ec2:
      aws_access_key: "{{aws_access_key}}"
      aws_secret_key: "{{aws_secret_key}}"
      key_name: "{{ec2_pem_name}}"
      instance_type: t2.micro
      image: ami-07d8796a2b0f8d29c
      wait: yes
      group: "{{ec2_sg_name}}"
      region: "eu-west-1"
      count: 1
      vpc_subnet_id: subnet-0624fd8b23c534077
      assign_public_ip: yes
      instance_tags:
        Name: "{{ec2_instance_name}}"

```

 App dependencies
```yml
---
- hosts: app
  gather_facts: yes
  become: yes
  tasks:
  -  name: syncing app folder
     synchronize:
       src: /home/ubuntu/app
       dest: ~/
  -  name: load a specific version of nodejs
     shell: curl -sl https://deb.nodesource.com/setup_6.x | sudo -E bash -
  -  name: install the required packages
     apt:
       pkg:
         - nginx
         - nodejs
         - npm
       update_cache: yes
  -  name: nginx configuration for reverse proxy
     synchronize:
       src: /home/ubuntu/app/default
       dest: /etc/nginx/sites-available/default
  -  name: nginx restart
     service: name=nginx state=restarted
  -  name: nginx enable
     service: name=nginx enabled=yes
  -  name: setting db variable
     lineinfile: dest=/home/ubuntu/.bashrc line='export DB_HOST=mongodb://10.0.2.190:27017/posts'

```

 DB dependencies
 ```yml
---
- hosts: db
  gather_facts: yes
  become: true
  tasks:
  -  name: installing mongodb
     apt:
       pkg: mongodb
       state: present
       update_cache: yes
  -  name: synchronize mongodb conf file
     synchronize:
       src: /home/ubuntu/app/mongodb.conf
       dest: /etc/
  -  name: restart mongodb
     service: name=mongodb state=restarted
  -  name: enable mongodb
     service: name=mongodb enabled=yes

 ```