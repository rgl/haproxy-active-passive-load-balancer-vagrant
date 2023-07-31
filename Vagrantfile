# to make sure the nodes are created in order, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

lb_ip = '10.42.0.10'
lb_fqdn = 'lb.example.com'

app_ip = '10.42.0.11'
app_fqdn = 'app.example.com'

web_ips = (1..2).map {|n| "10.42.0.2#{n}"}
web_fqdns = (1..2).map {|n| "web#{n}.example.com"}

extra_hosts = """
#{lb_ip} #{lb_fqdn}
#{app_ip} #{app_fqdn}
#{
  web_ips.zip(web_fqdns).map do |(ip, fqdn)|
    "#{ip} #{fqdn}\n"
  end
}
"""

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-22.04-amd64'
  config.vm.provider :libvirt do |lv, config|
    lv.memory = 1024
    lv.cpus = 4
    lv.cpu_mode = 'host-passthrough'
    #lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs', nfs_version: '4.2', nfs_udp: false
  end
  config.vm.define 'lb' do |config|
    config.vm.hostname = lb_fqdn
    config.vm.network :private_network, ip: lb_ip, libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.network :private_network, ip: app_ip, libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.provision :shell, path: 'provision-certificate.sh', args: [lb_fqdn, lb_ip]
    config.vm.provision :shell, path: 'provision-certificate.sh', args: [app_fqdn, app_ip]
    config.vm.provision :shell, path: 'provision-hosts.sh', args: [extra_hosts]
    config.vm.provision :shell, path: 'provision-common.sh'
    config.vm.provision :shell, path: 'provision-lb.sh'
  end
  web_ips.zip(web_fqdns).each_with_index do |(ip, fqdn), n|
    config.vm.define "web#{n+1}" do |config|
      config.vm.hostname = fqdn
      config.vm.network :private_network, ip: ip, libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
      config.vm.provision :shell, path: 'provision-common.sh'
      config.vm.provision :shell, path: 'provision-web.sh'
    end
  end
end
