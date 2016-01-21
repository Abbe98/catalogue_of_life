class cat_of_life_2015 {
    
  file { 'downloads':
    path => ['/home/bc/downloads'],
    ensure => 'directory',
    owner => 'bc',
    mode => 755,
    group => 'bc'
  }
    
  exec { "get-col":
    command => "wget http://www.catalogueoflife.org/services/res/col2015ac_linux.tar.gz -P /home/bc/downloads && tar xzf /home/bc/downloads/col2015ac_linux.tar.gz --directory /home/bc/downloads",
    cwd => "/home/bc/downloads",
    user => "bc",
    timeout => 5000,
    group => "bc",
    creates => "/home/bc/downloads/col2015ac_linux.tar.gz",
    require => File["downloads"]
  }
  
  exec { "secure-mariadb":
    command => "/home/bc/catalogue_of_life/provisioning/modules/mariadb/files/mysql-autosecure.sh hemmelig",
    require => Service["mysql"],
    unless => "ls `which mysql_secure_installation`.ran"
  }
  
  exec {'create-database':
      command => 'mysql -u root -phemmelig -e "create database if not exists col2015ac"',
      require => [Exec["secure-mariadb"], Exec["get-col"]]
  }

  exec {'import':
      command => 'tar zxvf /home/bc/downloads/col2015ac.sql.tar.gz -C /home/bc/downloads && mysql -u root -phemmelig col2015ac < /home/bc/downloads/col2015ac.sql',
      user => "bc",
      group => "bc",
      timeout => 3600,
      cwd => "/home/bc/downloads",
      require => [Service["mysql"], Exec["create-database"]],
      creates => "/home/bc/downloads/col2015ac.sql"
  }
  
  exec {'unpack-app':
      command => 'tar zxvf /home/bc/downloads/col2015ac_application.tar.gz -C /var/www/html ',
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