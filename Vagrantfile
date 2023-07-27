# to make sure the nodes are created in order, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-18.04-amd64'
  config.vm.provider :libvirt do |lv, config|
    lv.memory = 256
    lv.cpus = 4
    lv.cpu_mode = 'host-passthrough'
    #lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end
  config.vm.define 'lb' do |config|
    config.vm.hostname = 'lb.example.com'
    config.vm.network :private_network, ip: '10.42.0.10', libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.network :private_network, ip: '10.42.0.11', libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.network :private_network, ip: '10.42.0.12', libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.provision :shell, path: 'provision-certificate.sh', args: ['app1.example.com', '10.42.0.11']
    config.vm.provision :shell, path: 'provision-certificate.sh', args: ['app2.example.com', '10.42.0.12']
    config.vm.provision :shell, path: 'provision-common.sh'
    config.vm.provision :shell, path: 'provision-lb.sh'
  end
  (1..2).each do |n|
    config.vm.define "web#{n}" do |config|
      config.vm.hostname = "web#{n}.example.com"
      config.vm.network :private_network, ip: "10.42.0.2#{n}", libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
      config.vm.provision :shell, path: 'provision-common.sh'
      config.vm.provision :shell, path: 'provision-web.sh'
    end
  end
end
