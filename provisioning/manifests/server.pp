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
  package { ["epel-release", "wget", "gcc-c++", "curl", "make", "yum-utils", "dos2unix", "unzip", "lsof"]:
    ensure => present,
    require => Class["timezone"]
  }  
  
  file {"/etc/puppet/hiera.yaml":
    ensure => present
  }
   
  
  include httpd 
  include mariadb
  class { "cat_of_life_2015":
    user => "bc",
    group => "bc",
    provdir => "/home/bc"
  }
  class {"rails":
    is_server => true
  }
  class {"es":
    user => "bc",
    is_server => true
  }
 
}
