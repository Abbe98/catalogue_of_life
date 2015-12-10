class httpd {

  
  package { ["httpd"]:
    ensure => present,
    before => File["/etc/httpd/conf/httpd.conf"]
  }

  service {
    "httpd":
       ensure => true,
       enable => true,
       require => Package["httpd"],
       subscribe => [File["/etc/httpd/conf/httpd.conf"], Package["httpd"]]
  }
  
  file {
    "/etc/httpd/conf/httpd.conf":
       source => "puppet:///modules/httpd/httpd.conf",
       mode => 644,
       owner => root,
       group => root,
       require => Package["httpd"],
       notify => Service["httpd"],
  }

  file {
    "/etc/sysconfig/network":
       source => "puppet:///modules/httpd/network",
       mode => 644,
       owner => root,
       group => root,
       require => Package["httpd"],
       notify => Service["httpd"],
  }

  # file {
  #   "/etc/httpd/conf.d/httpd-vhosts.conf":
  #      source => "puppet:///modules/httpd/httpd-vhosts.conf",
  #      mode => 644,
  #      owner => root,
  #      group => root,
  #      require => Package["httpd"],
  #      notify => Service["httpd"],
  # }
  
    
  exec { "firewall-config-http":
    command => "firewall-cmd --zone=public --add-service=http --permanent && firewall-cmd --reload",
    unless => "firewall-cmd --query-service=http"
  }
    
  # enable mod_ldap?
  
}
