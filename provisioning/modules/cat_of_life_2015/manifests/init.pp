class cat_of_life_2015 ($user = 'vagrant',
                        $group = 'vagrant',
                        $provdir = '/vagrant/',
                        $mysql_root_pwd = 'hemmelig')  {
    
  file { 'downloads':
    path => ["/home/${user}/downloads"],
    ensure => "directory",
    owner => "${user}",
    mode => 755,
    group => "${group}"
  }
    
  exec { "get-col":
    command => "wget http://www.catalogueoflife.org/services/res/col2015ac_linux.tar.gz -P /home/${user}/downloads && tar xzf /home/${user}/downloads/col2015ac_linux.tar.gz --directory /home/${user}/downloads",
    cwd => "/home/${user}/downloads",
    user => "${user}",
    timeout => 5000,
    group => "${group}",
    creates => "/home/${user}/downloads/col2015ac_linux.tar.gz",
    require => File["downloads"]
  }
  
  exec { "secure-mariadb":
    command => "sh ${provdir}/catalogue_of_life/provisioning/modules/mariadb/files/mysql-autosecure.sh hemmelig",
    require => Service["mysql"],
    unless => "ls `which mysql_secure_installation`.ran"
  }
  
  exec {'create-database':
      command => "mysql -u root -p${mysql_root_pwd} -e 'create database if not exists col2015ac'",
      require => [Exec["secure-mariadb"], Exec["get-col"]]
  }

  exec {'import':
      command => "tar zxvf /home/${user}/downloads/col2015ac.sql.tar.gz -C /home/${user}/downloads && mysql -u root -p${mysql_root_pwd} col2015ac < /home/${user}/downloads/col2015ac.sql",
      user => "${user}",
      group => "${group}",
      timeout => 3600,
      cwd => "/home/${user}/downloads",
      require => [Service["mysql"], Exec["create-database"]],
      creates => "/home/${user}/downloads/col2015ac.sql"
  }
  
  exec {'unpack-app':
      command => "tar zxvf /home/${user}/downloads/col2015ac_application.tar.gz -C /var/www/html ",
      require => [Package["httpd"], Exec["get-col"]],
      notify => Service["httpd"],
      creates => "/var/www/html/col2015ac"
  }

  exec {'chown-app':
      command => 'chown -R apache:apache /var/www/html/col2015ac &&  chmod -R 777 /var/www/html/col2015ac',
      require => [Exec["unpack-app"]],
      notify => Service["httpd"]
  }
  
  package { ["php", "php-mysql", "php-xml"]:
    ensure => present,
    require => Package['MariaDB-server'],
  }  
  
  file {"/etc/httpd/conf.modules.d/00-rewrite.conf":
      source  => 'puppet:///modules/cat_of_life_2015/00-rewrite.conf',
      require => Package["httpd", "php-xml"],
      notify => Service["httpd"]
  }


  file { '/var/www/html/col2015ac/application/cache':
    path => ['/var/www/html/col2015ac/application/cache'],
    ensure => 'directory',
    owner => 'apache',
    group => 'apache',
    mode => 755,
    require => Exec["unpack-app"]
  }

  file { '/var/www/html/col2015ac/application/log':
    path => ['/var/www/html/col2015ac/application/log'],
    ensure => 'directory',
    owner => 'apache',
    group => 'apache',
    mode => 755,
    require => Exec["unpack-app"]
  }

  file {"/var/www/html/col2015ac/application/configs/config.ini":
    source  => 'puppet:///modules/cat_of_life_2015/config.ini',
    require => Exec["unpack-app"],
    owner => 'apache',
    group => 'apache',
    mode => 755,
    notify => Service["httpd"]
  }
  
  file {"/etc/httpd/conf.d/httpd-vhosts.conf":
      source  => 'puppet:///modules/cat_of_life_2015/httpd-vhosts.conf',
      require => Exec["unpack-app"],
      notify => Service["httpd"]
  }

      
}