
class es {
  
    exec {"es":
      command => "rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch"
    }
    
    exec {"es-key":
       command => "rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch"
    }
  
    file {"/etc/elasticsearch/elasticsearch.yml":
      source => "puppet:///modules/es/elasticsearch.yml",
      require => Package["elasticsearch"],
      notify => Service["elasticsearch"]
    }
    
    file {"/etc/yum.repos.d/elasticsearch.repo":
      source => "puppet:///modules/es/elasticsearch.repo",
      require => Exec["es-key"]
    }
      
    package {["java-1.8.0-openjdk", "elasticsearch"]: 
       ensure => present, 
       require => [Exec["es"], File["/etc/yum.repos.d/elasticsearch.repo"]],
       provider => 'yum'
   }
 
   exec {"es-automatisk-start":
     command => "chkconfig --add elasticsearch && chkconfig elasticsearch on",
     require => Package["elasticsearch"]
   }
   
   service {"elasticsearch":
     ensure => running,
     require => Exec["es-automatisk-start"]
   }

   
   
   exec { "allow access to port 9200":
     command => "firewall-cmd --permanent --zone=public --add-port=9200/tcp && firewall-cmd --reload",
   }
   exec { "allow access to port 5601":
     command => "firewall-cmd --permanent --zone=public --add-port=5601/tcp && firewall-cmd --reload",
   }
   
   # Trenger ikke denne siden selinux er disabled
   # exec {"selinux":
   #   command => "setsebool -P httpd_can_network_connect 1"
   # }
   exec { "get kibana":
     command => "wget https://download.elastic.co/kibana/kibana/kibana-4.3.1-linux-x64.tar.gz -P /home/vagrant/downloads  && tar xzf /home/vagrant/downloads/kibana-4.3.1-linux-x64.tar.gz -C /opt",
     cwd => "/home/vagrant",
     timeout => 1800,
     unless => "ls /opt/kibana-4.3.1-linux-x64"
   }

   file { '/opt/kibana':
     ensure => 'link',
     target => '/opt/kibana-4.3.1-linux-x64',
      require => Exec["get kibana"]
   }

   file { '/etc/systemd/system/kibana4.service':
     source => "puppet:///modules/es/kibana4.service",
     require => File["/opt/kibana"]
   }

   service {"kibana4":
     ensure => running,
     require => File["/etc/systemd/system/kibana4.service"]
   }
   
   exec {"kibana-sense":
     command => "/opt/kibana/bin/kibana plugin --install elastic/sense",
     require => Service["kibana4"],
     returns => [0, 70]
   }
       
}

