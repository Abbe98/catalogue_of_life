class mariadb {

# https://mariadb.com/blog/installing-mariadb-10-centos-7-rhel-7
    
  file { '/etc/yum.repos.d/mariadb.repo':
    source  => 'puppet:///modules/mariadb/mariadb.repo'
  }

  package { ['MariaDB-server', 'MariaDB-client']:
    ensure => present,
    require => [File['/etc/yum.repos.d/mariadb.repo'],Package["epel-release"]]
  }

  # Run mysql
  service { 'mysql':
    ensure  => running,
    require => Package['MariaDB-server'],
  }


  # We set the root password here
  # exec { 'secure_installation':
  #   #unless  => 'mysqladmin -uroot -proot status',
  #   command => "mysql_secure_installation",
  #   path    => ['/bin', '/usr/bin'],
  #   require => Service['mariadb'];
  # }
}