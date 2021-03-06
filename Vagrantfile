# -*- mode: ruby -*-
# vi: set ft=ruby ts=2 sw=2 tw=0 et :
require 'yaml'


boxes = YAML.load_file('vagrant-boxes.yml')

def create_box(hostname, cpus, memory, ip_address, box, ansible_playbook=nil, ansible_galaxy_requirements=nil, ansible_roles_path=nil)
  Vagrant.configure(2) do |config|
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    config.vm.define hostname do |vm_config|
      config.vm.provider :virtualbox do |v|
        v.name = hostname
        v.memory = memory
        v.cpus = cpus
      end
      vm_config.vm.box = box
      vm_config.vm.hostname = hostname
      vm_config.vm.network :private_network, ip: ip_address
      # provision box
      unless ansible_playbook.nil?
        vm_config.vm.provision :ansible do |ansible|
          ansible.playbook = ansible_playbook
          ansible.verbose = 'v'
          ansible.galaxy_role_file = ansible_galaxy_requirements unless ansible_galaxy_requirements.nil?
          ansible.galaxy_roles_path = ansible_roles_path unless ansible_roles_path.nil?
        end
      end
    end
  end
end


boxes['boxes'].each do |box|
  create_box(box['hostname'],
             box['cpus'],
             box['memory'],
             box['ip'],
             box['box'],
             box['ansible_playbook'],
             box['ansible_galaxy_requirements'],
             box['ansible_roles_path'])
end
