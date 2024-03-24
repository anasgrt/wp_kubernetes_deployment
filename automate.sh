#!/bin/bash

# Update package lists
sudo apt update -y

# Install Python3 and pip
sudo apt install python3-pip -y

# Display pip3 version
pip3 --version

# Install Python3.10 virtual environment
sudo apt install python3.10-venv -y

# Clone Kubespray repository
git clone https://github.com/kubernetes-sigs/kubespray.git

# Change to the Kubespray directory
cd kubespray

# Set variables
KUBESPRAYDIR=kubespray
VENVDIR=kubespray-venv

# Create and activate virtual environment
python3 -m venv $VENVDIR
source $VENVDIR/bin/activate

# Change to the Kubespray directory
cd $KUBESPRAYDIR

# Install Kubespray requirements
pip3 install -U -r requirements.txt

# Copy "inventory/sample" as "inventory/mycluster"
cp -rfp inventory/sample inventory/mycluster

# Create a new Kubespray inventory
echo -e "[kube_control_plane]\nlocalhost\n\n[kube_node]\nlocalhost\n\n[etcd]\nlocalhost\n\n[k8s_cluster:children]\nkube_control_plane\nkube_node\n\n[prod:children]\nkube_control_plane\nkube_node" > inventory/mycluster/hosts.yaml

echo -e "kube_version: v1.29.2\nhelm_enabled: true" > cluster-variable.yaml

# enable ingress-nginx as an addon
echo -e 'ingress_nginx_enabled: true\ningress_nginx_host_network: false\ningress_publish_status_address: ""' > inventory/mycluster/group_vars/k8s_cluster/addons.yml

# enable cert-manager as an addon
echo -e 'cert_manager_enabled: true\ncert_manager_namespace: "cert-manager"' >> inventory/mycluster/group_vars/k8s_cluster/addons.yml


# Deploy Kubespray
ansible-playbook -i inventory/mycluster/hosts.yaml -e @cluster-variable.yaml --become --become-user=root cluster.yml -e ansible_connection=local

# Getting the kubernetes credentials
sudo mkdir ~/.kube && sudo touch ~/.kube/config
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# check the accessibility to kubernetes cluster
# Create a new kubernetes namespace
kubectl create namespace wordpress

# Add helm repository and install it in the namespace "wordpress"
helm -n wordpress repo add wordpress https://anasgrt.github.io/wordpress-helm-chart/ && helm -n wordpress install wordpress wordpress/wordpress-helm-chart

# Check the status of the resources
kubectl get all -A