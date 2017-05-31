## -*- mode: ruby -*-
# vi: set ft=ruby :

# rubocop:disable all
VAGRANTFILE_API_VERSION = "2"
nb_nodes = 1
vm_memory ||= "2048"
vm_cpus ||= "2"
vm_cpu_cap ||= "50"
vm_local_disks = [32,10]
vm_shared_disks = []

nodes =""
(1..nb_nodes).each do |i|
 nodes="racnode#{i} #{nodes}"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |c|
  (1..nb_nodes).each do |i|
    puts "node is #{i}"
    c.vm.define vm_name = "node-%01d" % i  do |node|
      #i = nb_nodes+1-i
      node.vm.hostname = "node-#{i}"
      node.vm.boot_timeout = 900
      #c.vm.network "public_network", use_dhcp_assigned_default_route: true
      node.vm.provider :virtualbox do |vb|
        # VM resources
        vb.customize ["modifyvm", :id, "--memory", vm_memory]
        vb.customize ["modifyvm", :id, "--cpus", vm_cpus]
        vb.customize ["modifyvm", :id, "--cpuexecutioncap", vm_cpu_cap]
        port = 1

        # Create local disks
        disk=1
        vm_local_disks.each do |disk_size|
          puts "disk#{disk} #{vm_name}"
          if !File.exist?("disk#{disk}_#{vm_name}.vdi") and nb_nodes==i
            vb.customize ['createhd', '--filename', "disk#{disk}_#{vm_name}.vdi", '--size', disk_size * 1024, '--variant', 'Standard']
            vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', port, '--device', 0, '--type', 'hdd', '--medium', "disk#{disk}_#{vm_name}.vdi"]
            port += 1
            disk += 1
          end
        end

        # Create shared disks
        lun=1
        vm_shared_disks.each do |lun_size|
          puts "lun#{lun} #{vm_name}"
          if !File.exist?("lun#{lun}_#{vm_name}.vdi") and nb_nodes==i
            vb.customize ['createhd', '--filename', "lun#{lun}_#{vm_name}.vdi", '--size', lun_size * 1024, '--variant', 'fixed']
            vb.customize ['modifyhd', "lun#{lun}_#{vm_name}.vdi", '--type', 'shareable']
            vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', port, '--device', 0, '--type', 'hdd', '--medium', "lun#{lun}_#{vm_name}.vdi"]
            port += 1
            lun +=1
          end
        end
      end
    end
  end
#  c.vm.provision :chef_solo do |chef|
#    chef.add_recipe "redmine"
#  end
end
