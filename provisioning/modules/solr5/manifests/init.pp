
class solr5($version = '5.1.0')  {
  
  package { []:
    ensure => present
  }
  
  # file { 'indexes':
  #   path => ['/home/vagrant/indexes'],
  #   ensure => 'directory',
  #   owner => 'vagrant',
  #   mode => 755,
  #   group => 'vagrant'
  # }
  
  file { 'downloads':
    path => ['/home/vagrant/downloads'],
    ensure => 'directory',
    owner => 'vagrant',
    mode => 755,
    group => 'vagrant'
  }

  exec { "get solr":
#    command => "wget http://archive.apache.org/dist/lucene/solr/${version}/solr-${version}.tgz -P /home/vagrant/downloads  && tar xzf downloads/solr-${version}.tgz solr-${version}/bin/install_solr_service.sh --strip-components=2",
    command => "tar xzf /vagrant/downloads/solr-${version}.tgz solr-${version}/bin/install_solr_service.sh --strip-components=2",
    cwd => "/home/vagrant",
    user => "vagrant",
    timeout => 0,
    group => "vagrant",
    unless => "ls /home/vagrant/install_solr_service.sh"
  }

  exec { "install solr":
#  command => "/home/vagrant/install_solr_service.sh /home/vagrant/downloads/solr-${version}.tgz -i /opt -d /var/solr -u vagrant -s solr -p 8983",    cwd => "/home/vagrant",
  command => "/home/vagrant/install_solr_service.sh /vagrant/downloads/solr-${version}.tgz -i /opt -d /var/solr -u vagrant -s solr -p 8983",    cwd => "/home/vagrant",
    creates => "/opt/solr",
    require => [Package["java-1.8.0-openjdk", "unzip", "lsof"],Exec["get solr"]]
  }
   
  # file { 'core_dir':
  #   path => ['/var/solr/data/techproducts/'],
  #   ensure => 'directory',
  #   owner => 'vagrant',
  #   mode => 755,
  #   group => 'vagrant',
  #   require => Exec["install solr"]
  # }
  #
  
  exec { "create core":
    command => "/opt/solr/bin/solr create_core -c techproducts -d /opt/solr/server/solr/configsets/sample_techproducts_configs",
    creates => "/var/solr/data/techproducts",
    user => "vagrant",
    require => Exec["install solr"]
  }

  #file { "/var/solr/solr.in.sh":
  # file { "solr.in.sh":
  #   path => "/vagrant/solr_home/solr.in.sh",
  #   source => "puppet:///modules/solr5/solr.in.sh",
  #   mode => 744,
  #   require => Exec["install solr"]
  # }

  file { '/home/vagrant/www':
    ensure => link,
    target => '/vagrant/www'
  }

  file { "www.xml":
    path=>"/opt/solr/server/contexts/www.xml",
    source => "puppet:///modules/solr5/www.xml",
    mode => 644,
    owner => "vagrant",
    group => "vagrant",
    require => [File["/home/vagrant/www"],Exec["install solr"]]
  }

  exec { "allow access to port 8983":
    command => "firewall-cmd --permanent --zone=public --add-port=8983/tcp && firewall-cmd --reload",
    require => Exec["get solr"], 
    unless => "firewall-cmd --query-port=8983/tcp"
  }

  exec {"chkconfig solr":
    command => "chkconfig solr on",
    require => Exec["create core"],
    unless => "chkconfig --list solr | grep solr"
  }

   # exec {"restart solr":
   #   command => "/sbin/service solr restart",
   #   require => File["www.xml"]
   # }
  
 
}

