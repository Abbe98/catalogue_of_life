# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
   
  # config.vm.box = "puphpet/centos65-x64"
  config.vm.box = "puppetlabs/centos-7.0-64-puppet"
  config.vm.box_version = "1.0.1"
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  #config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 80, host: 8080
  #config.vm.network "forwarded_port", guest: 8080, host: 8083
  #config.vm.network "forwarded_port", guest: 8983, host: 8985
  # config.vm.network "forwarded_port", guest: 8080, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.8"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder "./", "/vagrant", mount_options: ["dmode=777,fmode=777"]
  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
   config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
     vb.name = "catalogue"
     vb.memory = "2048"
     
     # if ARGV[0] == "up"
     #   config.vm.provision "shell", :run => "always", path: "provisioning/increase_swap.sh"
     # end
     
   end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  #
  # Create a generated file with the ssh developers own key, for installation
  # by puppet into the VM.
  local_developer_authorized_keys_filename = File.join(File.dirname(__FILE__),"provisioning/files/local_developer.authorized_keys")

  local_developer_public_keys = %x{ssh-add -L}
  case local_developer_public_keys
  when /^ssh-/ then
    File.open(local_developer_authorized_keys_filename,"w+"){|file|file.write local_developer_public_keys}
  else
    puts %{You must have a local ssh key, that is available to 'ssh-add -L'.}
    exit 1
  end
  
  
  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision :puppet, :module_path => "provisioning/modules" do |puppet|
    puppet.hiera_config_path = "provisioning/hiera.yaml"
    puppet.manifests_path    = "provisioning/manifests"
    puppet.manifest_file     = "development.pp"
  #   #puppet.options = "--verbose --debug"
  end
  
  config.vm.provision "shell", :run => "always", inline: <<-SHELL
    echo "Catalogue of Life: http://192.168.33.8/col2015ac"
    #echo "Logge inn med ssh som oracle:    ssh oracle@192.168.33.9"
    #echo "Logge inn med ssh som iknowbase: ssh iknowbase@192.168.33.9"
    #echo "iKnowBase console: http://localhost:8080/ikb$console"
    #echo "Solr admin: http://localhost:8983/"
    #echo "se provisioning/modules/oracle/manifests/init.pp for manuelle steg for å installere oracle"
  SHELL
  
end
