
# http://docs.mongodb.org/manual/tutorial/install-mongodb-on-red-hat-centos-or-fedora-linux/
class rails ($mysql_root_pwd = 'hemmelig') {
 
  
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

  
  exec {'create-dbuser':
      command => "mysql -u root -p${mysql_root_pwd} -e 'grant all on *.* to \"speciesdb\"@\"localhost\" identified by \"passord\"'",
      require => [Exec["secure-mariadb"]]
  }

}
