#!/bin/bash

cat <<EOF > /tmp/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF


cat <<EOF > /tmp/docker.repo
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

sudo mv /tmp/kubernetes.repo /etc/yum.repos.d/kubernetes.repo
sudo chmod 644 /etc/yum.repos.d/kubernetes.repo
sudo chown root:root /etc/yum.repos.d/kubernetes.repo

sudo mv /tmp/docker.repo /etc/yum.repos.d/docker.repo
sudo chmod 644 /etc/yum.repos.d/docker.repo
sudo chown root:root /etc/yum.repos.d/docker.repo

sudo yum -y install deltarpm epel-release unzip

sudo yum makecache

sudo setenforce 0

sudo yum -y install kubelet-1.9.6-0 kubeadm-1.9.6-0 kubectl-1.9.6-0 kubernetes-cni-0.6.0-0 ca-certificates docker-engine-1.12.6
sudo update-ca-trust force-enable

sudo groupadd docker
sudo usermod -aG docker `whoami`

sudo systemctl enable docker && sudo systemctl start docker

# we need to disable swaps before use
swapon -s | awk '{print "sudo swapoff " $1}' | grep -v "Filename" | sudo sh -

ctx logger info "Reload kubernetes"

sudo systemctl daemon-reload
sudo systemctl enable kubelet.service
sudo systemctl stop kubelet && sleep 20 && sudo systemctl start kubelet

for retry_count in {1..10}
do
	status=`sudo systemctl status kubelet | grep "Active:"| awk '{print $2}'`
	ctx logger info "#${retry_count}: Kubelet state: ${status}"
	if [ "z$status" == 'zactive' ]; then
		break
	else
		ctx logger info "Wait little more."
		sleep 10
	fi
done
