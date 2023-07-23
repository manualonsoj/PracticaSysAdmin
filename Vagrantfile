# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_IMAGE = "ubuntu/focal64"

Vagrant.configure("2") do |config|
  config.vm.define "server1" do |server1|
    server1.vm.box = BOX_IMAGE
    server1.vm.box_check_update = false
    server1.vm.hostname = "server1"
    server1.vm.network "forwarded_port", guest: 80, host: 8081
    server1.vm.network "private_network", ip: "192.168.56.10", nic_type: "virtio", virtualbox__intnet: "keepcooding"
    server1.vm.provider "virtualbox" do |vb|
      vb.name = "server1"
	    vb.memory = "2048"
      vb.cpus = "1"
	    vb.default_nic_type = "virtio"
      file_to_disk1 = "extradisk1.vmdk"
      unless File.exist?(file_to_disk1)
          vb.customize [ "createmedium", "disk", "--filename", "extradisk1.vmdk", "--format", "vmdk", "--size", 1024 * 1 ]
      end
      vb.customize [ "storageattach", "server1" , "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk1]
    end
    server1.vm.provision "shell", path: "provision_wp.sh"
  end
  
 config.vm.define "server2" do |server2|
    server2.vm.box = BOX_IMAGE
    server2.vm.box_check_update = false
    server2.vm.hostname = "server2"
    server2.vm.network "forwarded_port", guest: 5601, host: 8056
    server2.vm.network "forwarded_port", guest: 9200, host: 9200 
    server2.vm.network "private_network", ip: "192.168.56.11", nic_type: "virtio", virtualbox__intnet: "keepcooding"
    server2.vm.provider "virtualbox" do |vb|
      vb.name = "server2"
      vb.memory = "4096"
      vb.cpus = "2"
      vb.default_nic_type = "virtio"
      file_to_disk1 = "extradisk2.vmdk"
      unless File.exist?(file_to_disk1)
          vb.customize [ "createmedium", "disk", "--filename", "extradisk2.vmdk", "--format", "vmdk", "--size", 1024 * 1 ]
      end
      vb.customize [ "storageattach", "server2" , "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk1]
    end
    server2.vm.provision "shell", path: "provision_elk.sh"
  end
end
