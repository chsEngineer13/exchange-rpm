# -*- mode: ruby -*-
# vi: set ft=ruby :
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/centos-6.8"

  #config.vbguest.auto_update = ture
  #config.vbguest.no_remote = false

  #config.vm.provision :shell, path: "dev/bootstrap.sh"

  config.ssh.shell = "sh"
  # avoid failures that may be mac-specific and/or version-specific
  config.ssh.insert_key = false

  ## create a private network visible only to the host machine
  config.vm.network :private_network, ip: "192.168.99.110"

  ## assign a static ip visible to others on the network.
  # config.vm.network :public_network, :bridge => 'en0: Wi-Fi (AirPort)', ip: "192.168.10.222", netmask: "255.255.255.0"


  # Example of share an additional folder to the guest VM.
  # config.vm.synced_folder "../MapLoom", "/MapLoom"
  config.vm.synced_folder "../django-fulcrum", "/django-fulcrum"


  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "5096", "--cpus", "2"]
  end
end
