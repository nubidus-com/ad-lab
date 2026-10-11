# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  config.vm.provider "vmware_desktop" do |v|
    v.gui = true
    v.memory = 3072
    v.cpus = 2
  end

  # VirtualBox 7.1+ on Apple Silicon (ARM64 guests only)
  config.vm.provider "virtualbox" do |v|
    v.gui = true
    v.memory = 3072
    v.cpus = 2
  end

  # disable SSH forwarded port

  # Disable default shared folder:
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Configure a Shared Folder:
  config.vm.synced_folder "/Users/ddemirci/Documents/VM_SHARED",
                          "C:/Shared-Folder"


  config.vm.define "win-dc01" do |dc|
    dc.vm.guest = :windows
    dc.vm.communicator = "winrm"
    dc.vm.boot_timeout = 300
    dc.vm.graceful_halt_timeout = 300
    dc.winrm.transport = :plaintext
    dc.winrm.basic_auth_only = true
    dc.winrm.retry_limit = 30
    dc.winrm.retry_delay = 10
    dc.vm.box = "lab/windows-server-2025-arm64"
    dc.vm.network "private_network", ip: "192.168.56.10"

    # Disable default port forwards
    dc.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", disabled: true
    dc.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm-default", disabled: true
    dc.vm.network :forwarded_port, guest: 5986, host: 5986, id: "winrm-ssl", disabled: true
    dc.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true

    # Port forward
    dc.vm.network :forwarded_port, guest: 3389, host: 23389, id: "msrdp"
    dc.vm.network :forwarded_port, guest: 5985, host: 25985, id: "winrm"

    # Provision Ansible remoting
    dc.vm.provision "hostonlyIp", type: "shell",
      path: "./Shared-Folder/ps1/1-configure-ip-dc.ps1"

    dc.vm.provision "ansibleRemoting", type: "shell",
      path: "./Shared-Folder/ps1/ConfigureRemotingForAnsible.ps1"


end

  config.vm.define "win-srv01" do |winsrv1|
    winsrv1.vm.guest = :windows
    winsrv1.vm.communicator = "winrm"
    winsrv1.vm.boot_timeout = 600
    winsrv1.vm.graceful_halt_timeout = 600
    winsrv1.winrm.transport = :plaintext
    winsrv1.winrm.basic_auth_only = true
    winsrv1.winrm.retry_limit = 30
    winsrv1.winrm.retry_delay = 10
    winsrv1.vm.box = "lab/windows-server-2025-arm64"
    winsrv1.vm.network "private_network", ip: "192.168.56.11"

    # Disable default port forwards
    winsrv1.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", disabled: true
    winsrv1.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm-default", disabled: true
    winsrv1.vm.network :forwarded_port, guest: 5986, host: 5986, id: "winrm-ssl", disabled: true
    winsrv1.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true

    # Port forward
    winsrv1.vm.network :forwarded_port, guest: 3389, host: 33389, id: "msrdp"
    winsrv1.vm.network :forwarded_port, guest: 5985, host: 35985, id: "winrm"

    winsrv1.vm.provision "hostonlyIp", type: "shell",
      path: "./Shared-Folder/ps1/2-configure-ip-srv01.ps1"

    winsrv1.vm.provision "ansibleRemoting", type: "shell",
      path: "./Shared-Folder/ps1/ConfigureRemotingForAnsible.ps1"
  end

  config.vm.define "win-srv02" do |winsrv2|
    winsrv2.vm.guest = :windows
    winsrv2.vm.communicator = "winrm"
    winsrv2.vm.boot_timeout = 600
    winsrv2.vm.graceful_halt_timeout = 600
    winsrv2.winrm.transport = :plaintext
    winsrv2.winrm.basic_auth_only = true
    winsrv2.winrm.retry_limit = 30
    winsrv2.winrm.retry_delay = 10
    winsrv2.vm.box = "lab/windows-server-2025-arm64"
    winsrv2.vm.network "private_network", ip: "192.168.56.12"

    # Disable default port forwards
    winsrv2.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", disabled: true
    winsrv2.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm-default", disabled: true
    winsrv2.vm.network :forwarded_port, guest: 5986, host: 5986, id: "winrm-ssl", disabled: true
    winsrv2.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true

    # Port forward
    winsrv2.vm.network :forwarded_port, guest: 3389, host: 43389, id: "msrdp"
    winsrv2.vm.network :forwarded_port, guest: 5985, host: 45985, id: "winrm"

    winsrv2.vm.provision "hostonlyIp", type: "shell",
      path: "./Shared-Folder/ps1/3-configure-ip-srv02.ps1"

    winsrv2.vm.provision "ansibleRemoting", type: "shell",
      path: "./Shared-Folder/ps1/ConfigureRemotingForAnsible.ps1"
  end

  config.vm.define "win-client01" do |client|
    client.vm.guest = :windows
    client.vm.communicator = "winrm"
    client.vm.boot_timeout = 600
    client.vm.graceful_halt_timeout = 600
    client.winrm.transport = :plaintext
    client.winrm.basic_auth_only = true
    client.winrm.retry_limit = 30
    client.winrm.retry_delay = 10
    client.vm.box = "lab/windows-11-arm64"
    client.vm.network "private_network", ip: "192.168.56.13"
    client.vm.provider "virtualbox" do |v|
      v.default_nic_type = "virtio"
      v.customize ["modifyvm", :id, "--nic-type2", "virtio"]
    end

    # Disable default port forwards
    client.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", disabled: true
    client.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm-default", disabled: true
    client.vm.network :forwarded_port, guest: 5986, host: 5986, id: "winrm-ssl", disabled: true
    client.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true

    # Port forward
    client.vm.network :forwarded_port, guest: 3389, host: 53389, id: "msrdp"
    client.vm.network :forwarded_port, guest: 5985, host: 55985, id: "winrm"

    client.vm.provision "hostonlyIp", type: "shell",
      path: "./Shared-Folder/ps1/4-configure-ip-client.ps1"

    client.vm.provision "ansibleRemoting", type: "shell",
      path: "./Shared-Folder/ps1/ConfigureRemotingForAnsible.ps1"
  end

  config.vm.define "linux-srv01" do |linsrv1|
    linsrv1.vm.box = "bento/ubuntu-24.04"
    linsrv1.vm.box_architecture = "arm64"
    linsrv1.vm.network "private_network", ip: "192.168.56.14"

    # Disable default ssh forwarding port
    linsrv1.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
    linsrv1.vm.network :forwarded_port, guest: 22, host: 6222, id: "msrdp"

    # Adjust the shared-folder:
    linsrv1.vm.synced_folder "/Users/ddemirci/Documents/VM_SHARED",
                          "/home/vagrant/Shared-Folder", disabled: true
    # linsrv1.vm.synced_folder "E:/VMWare_Storage/Virtual Machines/Shared-Folder",
    #                        "/home/vagrant/Shared-Folder"
  end

end

