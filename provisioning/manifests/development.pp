# http://projects.puppetlabs.com/projects/1/wiki/File_Permission_Check_Patterns

define check_mode($mode) {
  exec { "/bin/chmod $mode $name":
    unless => "/bin/sh -c '[ $(/usr/bin/stat -c %a $name) == $mode ]'",
  }
}

if versioncmp($::puppetversion,'3.6.1') >= 0 {

  $allow_virtual_packages = hiera('allow_virtual_packages',false)

  Package {
    allow_virtual => $allow_virtual_packages,
  }
  
}

node default {

  class { "timezone":
    region => "Europe",
    locality => "Oslo",
  }    
    
  Exec {
    path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    require => Class["timezone"]
  }
  
  # exec {"increase swap":
  #   command => "/vagrant/provisioning/increase_swap.sh",
  #   unless => "grep swap /etc/fstab"
  # }

  # exec { "yum clean":
  #   command => "yum clean all && yum makecache fast",
  #   require => [Class["timezone"],Exec["increase swap"]]
  # }
  
  package { ["epel-release", "wget", "curl", "make", "yum-utils", "dos2unix", "unzip", "lsof"]:
    ensure => present,
    require => Class["timezone"]
  }  
    
  file {
    "/etc/environment":
       source => "/vagrant/provisioning/files/environment",
       mode => 644,
       owner => root,
       group => root
  }
  
  file { "/home/vagrant/.bash_profile":
    source => "/vagrant/provisioning/files/bash_profile",
    mode => 644,
    owner => "vagrant",
    group => "vagrant"
  } 
  
  file { "/etc/hosts":
    source => "/vagrant/provisioning/files/hosts",
    mode => 644,
  } 
   
  # installerer Oracle først siden den trenger tid til å starte før jeg kan opprette bruker, osv. 
  # class { "oracle":
  #   db_user => "iknowbase",
  #   db_password => "hemmelig"
  # }

  #include httpd

#  class { "solr5": 
#    version => "5.2.1" 
#  }
  
 include httpd 
 include mariadb 
 include cat_of_life_2015
 
}
