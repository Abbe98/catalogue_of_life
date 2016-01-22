
# http://docs.mongodb.org/manual/tutorial/install-mongodb-on-red-hat-centos-or-fedora-linux/
class rails ($mysql_root_pwd = 'hemmelig', $is_server = false) {
 
  
  package { ["ruby-devel", "rubygem-nokogiri", "mariadb-devel", "openssl", "openssl-devel", "zlib", "nodejs", "apr-devel", "apr-util-devel", "libcurl", "libcurl-devel", "httpd-devel", "mod_passenger"]:
    ensure => present,
    require => [Package["epel-release"], Exec["passenger-repos"]]
  }
  
  package { ["rails"]:
    ensure => 'installed',
    provider => gem,
    require => Package["ruby-devel"]
  }
  
  exec {"passenger-repos":
      command => "curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo", 
      unless => "ls /etc/yum.repos.d/passenger.repo"
  }


  unless $is_server {
    exec { "firewall-config-railsp":
      command => "firewall-cmd --zone=public --add-port=3000/tcp --permanent && firewall-cmd --reload",
      unless => "firewall-cmd --query-port=3000/tcp"
    }
  }
  
  # package { ["passenger"]:
  #     ensure   => "installed",
  #     provider => "gem",
  #     require => Package["apr-util-devel", "apr-devel", "httpd-devel"]
  # }
  
  # exec { "apache2-mod-passenger":
  #   command => "passenger-install-apache2-module --auto",
  #   require => Package["passenger", "httpd"]
  # }
  
  if $is_server {  
     file { "/etc/httpd/conf.d/speciesdb_prod.conf":
       source => "puppet:///modules/rails/speciesdb_prod.conf",
       mode => 644,
       owner => root,
       group => root,
       require => Package["mod_passenger"],
       notify => Service["httpd"],
     }
  } else {
     file { "/etc/httpd/conf.d/speciesdb_dev.conf":
       source => "puppet:///modules/rails/speciesdb_dev.conf",
       mode => 644,
       owner => root,
       group => root,
       require => Package["mod_passenger"],
       notify => Service["httpd"],
     }
  }
    
  file { "/etc/httpd/conf.modules.d/10-passenger.conf":
       source => "puppet:///modules/rails/10-passenger.conf",
       mode => 644,
       owner => root,
       group => root,
       require => Package["mod_passenger"],
       notify => Service["httpd"],
  }
  
  exec {'create-dbuser':
      command => "mysql -u root -p${mysql_root_pwd} -e 'grant all on *.* to \"speciesdb\"@\"localhost\" identified by \"passord\"'",
      require => [Exec["secure-mariadb"]]
  }
  
  exec { "firewall-config-http-81":
    command => "firewall-cmd --zone=public --add-port=81/tcp --permanent && firewall-cmd --reload",
    unless => "firewall-cmd --query-port=81/tcp"
  }
  
}
