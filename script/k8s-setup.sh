#!/bin/bash
# =============================================================================
# Kubernetes Cluster Setup with Calico CNI
# Ubuntu 22.04 (jammy) — matches vagrant box
#
# References:
#   - Kubernetes install: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#   - kubeadm init:       https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
#   - Calico install:     https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
#   - Calico manifest:    https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
#   - kubeadm join:       https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/
# =============================================================================


# =============================================================================
# SECTION 1 — PRE-REQUISITES (run on ALL nodes: control plane + workers)
# =============================================================================

# Disable swap (K8s requires swap off)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
modprobe overlay
modprobe br_netfilter

# Persist kernel modules across reboots
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Set required sysctl params
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system


# =============================================================================
# SECTION 2 — INSTALL CONTAINERD (run on ALL nodes)
# =============================================================================

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y containerd.io

# Generate default config and enable SystemdCgroup
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd


# =============================================================================
# SECTION 3 — INSTALL kubeadm, kubelet, kubectl (run on ALL nodes)
# =============================================================================

apt-get install -y apt-transport-https

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet


# =============================================================================
# SECTION 4 — INITIALISE CONTROL PLANE (run on CONTROL PLANE only)
# =============================================================================

# --pod-network-cidr must match Calico's default (192.168.0.0/16)
kubeadm init \
  --apiserver-advertise-address=192.168.56.10 \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket=unix:///run/containerd/containerd.sock

# Configure kubectl for the current user (run as root or adjust $HOME)
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config


# =============================================================================
# SECTION 5 — INSTALL CALICO CNI (run on CONTROL PLANE only)
# =============================================================================

# Install the Tigera operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml

# Install Calico custom resources (uses 192.168.0.0/16 — matches kubeadm init above)
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml

# Watch until all Calico pods are Running before joining workers
watch kubectl get pods -n calico-system


# =============================================================================
# SECTION 6 — GENERATE JOIN COMMAND (run on CONTROL PLANE, save the output)
# =============================================================================

# This prints the full kubeadm join command including the token and CA hash.
# Copy the output and run it on each worker node.
kubeadm token create --print-join-command


# =============================================================================
# SECTION 7 — JOIN WORKER NODES (run on each WORKER NODE)
# =============================================================================

# Replace the values below with the actual output from Section 6.
# Example:
#
# kubeadm join 192.168.56.10:6443 \
#   --token <token> \
#   --discovery-token-ca-cert-hash sha256:<hash>


# =============================================================================
# SECTION 8 — VERIFY CLUSTER (run on CONTROL PLANE)
# =============================================================================

# All nodes should show Ready status (may take 1-2 min after workers join)
kubectl get nodes -o wide

# All system pods should be Running
kubectl get pods -A
