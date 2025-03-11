#!/bin/bash

echo ".........----------------#################._.-.-INSTALL-.-._.#################----------------........."

PS1='\[\e[01;36m\]\u\[\e[01;37m\]@\[\e[01;33m\]\H\[\e[01;37m\]:\[\e[01;32m\]\w\[\e[01;37m\]\$\[\033[0;37m\] '
echo "PS1='$PS1'" >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc
source ~/.bashrc

# System Update & Cleanup
apt-get autoremove -y
apt-get update && apt-get upgrade -y
systemctl daemon-reload

# Install Dependencies
apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# Add Kubernetes Repo (Updated Method)
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | tee /etc/apt/keyrings/kubernetes-apt-keyring.asc
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

KUBE_VERSION=1.30.0
apt-get update
apt-get install -y docker.io vim build-essential jq python3-pip kubelet=${KUBE_VERSION}-1 kubectl=${KUBE_VERSION}-1 kubeadm=${KUBE_VERSION}-1

pip3 install jc

### UUID of VM (Comment if not on Cloud)
jc dmidecode | jq .[1].values.uuid -r

# Configure Docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker
systemctl enable docker
systemctl enable kubelet
systemctl start kubelet

echo ".........----------------#################._.-.-KUBERNETES-.-._.#################----------------........."
rm -rf /root/.kube/config
kubeadm reset -f

# Initialize Kubernetes Cluster
kubeadm init --kubernetes-version=${KUBE_VERSION} --skip-token-print

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config

# Install Calico CNI (Weave is outdated)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

sleep 60

# Untaint Control Plane Node
kubectl taint node $(kubectl get nodes -o=jsonpath='{.items[].metadata.name}') node-role.kubernetes.io/control-plane:NoSchedule-

kubectl get nodes -o wide

echo ".........----------------#################._.-.-JAVA & MAVEN-.-._.#################----------------........."
sudo apt install openjdk-11-jdk -y
java -version
sudo apt install -y maven
mvn -v

echo ".........----------------#################._.-.-JENKINS-.-._.#################----------------........."

# Add Jenkins Repo (Updated Method)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list

sudo apt update
sudo apt install -y jenkins
systemctl daemon-reload
systemctl enable jenkins
sudo systemctl start jenkins
sudo usermod -aG docker jenkins
echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo ".........----------------#################._.-.-COMPLETED-.-._.#################----------------........."
