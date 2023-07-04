#!/bin/bash


# Setup for Control Plane (Master) servers
set -euxo pipefail

if [ ! -s $TOOLS_DIR ]; then mkdir -p $TOOLS_DIR ; fi ;
HUBBLECLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt) ; 

_install_helm() {
	local helm_version="$1" ;
	echo "Installing Helm $helm_version .. " ;

	curl -C - --output-dir $TOOLS_DIR/bin -L --remote-name-all https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz ; 
	sudo tar --strip-components 1 -xzvf $TOOLS_DIR/bin/helm-${helm_version}-linux-amd64.tar.gz linux-amd64/helm ;
	sudo mv helm /usr/local/bin/helm ;
}

_install_ciliumexec() {
	echo "Installing CiliumExec .. " ;
	
	curl -C - --output-dir $TOOLS_DIR/bin -sLO https://raw.githubusercontent.com/cilium/cilium/master/contrib/k8s/k8s-cilium-exec.sh ;
	chmod +x $TOOLS_DIR/bin/k8s-cilium-exec.sh ;
	cp $TOOLS_DIR/bin/k8s-cilium-exec.sh /usr/local/bin ;
}

_install_ciliumcli() {
	local ciliumcli_version="$1" ;
	echo "Installing CiliumCLI $ciliumcli_version .. " ;

	curl -C - --output-dir $TOOLS_DIR/bin -L --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${ciliumcli_version}/cilium-linux-386.tar.gz ;
	sudo tar xzvfC $TOOLS_DIR/bin/cilium-linux-386.tar.gz /usr/local/bin ;
}

_install_hubblecli() {
	local hubblecli_version="$1" ;
	echo "Installing HubbleCLI $hubblecli_version .. " ;

	curl -C - --output-dir $TOOLS_DIR/bin -L --remote-name-all https://github.com/cilium/hubble/releases/download/${hubblecli_version}/hubble-linux-amd64.tar.gz ;
	sudo tar xzvfC $TOOLS_DIR/bin/hubble-linux-amd64.tar.gz /usr/local/bin ;
}

_install_kyvernocli() {
	local kyvernocli_version="$1" ;
	echo "Installing KyvernoCLI $kyvernocli_version .. " ;
	curl -C - --output-dir $TOOLS_DIR/bin -L --remote-name-all https://github.com/kyverno/kyverno/releases/download/${kyvernocli_version}/kyverno-cli_${kyvernocli_version}_linux_x86_64.tar.gz ;
	sudo tar xzvfC $TOOLS_DIR/bin/kyverno-cli_${kyvernocli_version}_linux_x86_64.tar.gz /usr/local/bin ;
}

_install_yq() {
	local yq_version="$1" ;
	echo "Installing YQ $yq_version .. " ;

	curl -C - --output-dir $TOOLS_DIR/bin -L --remote-name-all https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64.tar.gz ;
	sudo tar xzvfC $TOOLS_DIR/bin/yq_linux_amd64.tar.gz . ;
	sudo mv yq_linux_amd64 /usr/local/bin/yq ;
	sudo rm install-man-page.sh yq.1 ;
}

_install_flux() {
	local flux_version="$1" ;
	echo "Installing Flux $flux_version .. " ;
	curl -C - --output-dir $TOOLS_DIR/bin -L --remote-name-all https://github.com/fluxcd/flux2/releases/download/v${flux_version}/flux_${flux_version}_linux_amd64.tar.gz ;
	sudo tar xzvfC $TOOLS_DIR/bin/flux_${flux_version}_linux_amd64.tar.gz . ;
	sudo mv flux /usr/local/bin/ ;
}

_install_etcdctl() {
	local etcdctl_version="$1" ;	
	local etcdctl_version_full="etcd-${etcdctl_version}-linux-amd64" ;
	echo "Installing Etcdctl $etcdctl_version ($etcdctl_version_full) .. " ;
	wget -P $TOOLS_DIR/bin/ -nc https://github.com/etcd-io/etcd/releases/download/${etcdctl_version}/${etcdctl_version_full}.tar.gz ;
	tar xzf $TOOLS_DIR/bin/${etcdctl_version_full}.tar.gz ;
	sudo mv ${etcdctl_version_full}/etcdctl /usr/bin/ ;
	rm -rf ${etcdctl_version_full} ;
}

install_lab_tools() {

	_install_helm $HELM_VERSION ;
	_install_ciliumcli $CILIUMCLI_VERSION ;
	if [ ! -z $CILIUMEXEC_VERSION ]; then _install_ciliumexec ; fi ;
	if [ ! -z $HUBBLECLI_VERSION ]; then _install_hubblecli $HUBBLECLI_VERSION ; fi ;
	_install_kyvernocli $KYVERNOCLI_VERSION ;
	_install_yq $YQ_VERSION ;
	_install_flux $FLUX_VERSION ;
	_install_etcdctl $ETCDCTL_VERSION ;

}

install_helpful_tools() {
	# Adding misc tools and settings 
	### Install some utils
	apt-get update
	apt-get install -y bash-completion binutils net-tools dnsutils jq  apt-transport-https
}

vim_settings() {
	# global .vimrc
	cat > /etc/vimrc << EOF
set number
set hlsearch
set showmatch
set tabstop=2
set shiftwidth=2
syntax enable
set noswapfile
try
	colorscheme ron
catch
endtry
set background=dark
EOF

}

bash_settings() {
	# 'global' .bashrc settings
	cat > /etc/profile.d/misc-bashrc.sh << EOF
source /etc/bash_completion
source <(cilium completion bash)
source <(crictl completion bash)
source <(kubeadm completion bash)
source <(helm completion bash)
source <(yq shell-completion bash)
source <(flux completion bash)
source <(kubectl completion bash)
alias k=kubectl
alias c=clear
complete -F __start_kubectl k
EOF

}

swap_settings() {
	# disable linux swap and remove any existing swap partitions
	swapoff -a
	sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}


install_helpful_tools ;
vim_settings ;
bash_settings ;
swap_settings ;
install_lab_tools ;
echo "OK." ;