
# http://docs.mongodb.org/manual/tutorial/install-mongodb-on-red-hat-centos-or-fedora-linux/
class rails {
 
  
  package { ["ruby-devel", "rubygem-nokogiri", "mariadb-devel", "openssl", "openssl-devel", "zlib", "nodejs"]:
    ensure => present,
    require => Package["epel-release"]
  }
  
  package { ["rails"]:
    ensure => 'installed',
    provider => gem,
    require => Package["ruby-devel"]
  }


  exec { "firewall-config-railsp":
    command => "firewall-cmd --zone=public --add-port=3000/tcp --permanent && firewall-cmd --reload",
    unless => "firewall-cmd --query-port=3000/tcp"
  }
    
  # package { ["mysql2"]:
  #   ensure => 'installed',
  #   provider => gem,
  #   require => Package["rails", "mariadb-devel", "openssl",  "openssl-devel", "zlib"]
  # }
  
  
}
