####
#
# General purpose puppet file
#

# Required packages
$requiredPackages = [
  'apache2',
  'mysql-server',
  'mysql-client',
]
package { $requiredPackages:
  ensure => latest,
}

# Extra packages that make me happy
$extraPackages = [
  'vim',
]
package { $extraPackages:
  ensure => latest,
}

# Packages that need to notify apache2
$notifyApache2Packages = [
  'libapache2-mod-php5',
  'php5-mysql',
  'php5-mcrypt',
  'php5-curl',
  'php5-gd',
  'php5-json',
]
package { $notifyApache2Packages:
  ensure => latest,
  notify => Service['apache2'],
}

# Apache Stuff
service { 'apache2':
  ensure  => running,
  require => Package['apache2'],
}
$vhost = "
<VirtualHost *:80>
  ServerName www.localhost.com
  DocumentRoot /var/www/whmcs/whmcs
  <Directory /var/www/whmcs/whmcs>
    AllowOverride All
  </Directory>
</VirtualHost>
"
file { '/etc/apache2/sites-available/default':
  ensure  => present,
  content => "$vhost",
  notify  => Service['apache2'],
}

# MySQL stuff
service { 'mysql':
  ensure  => running,
  require => Package['mysql-server'],
}

####
#
# ionCube install
#
exec { 'ioncube.download':
  command => '/usr/bin/wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz',
  creates => '/tmp/ioncube_loaders_lin_x86-64.tar.gz',
  cwd     => '/tmp',
}

exec { 'ioncube.extract':
  command => '/bin/tar -xzf ioncube_loaders_lin_x86-64.tar.gz',
  creates => '/tmp/ioncube/',
  cwd     => '/tmp',
  require => Exec['ioncube.download'],
}

exec { 'ioncube.copy':
  command => '/bin/cp /tmp/ioncube/*.so /usr/lib/php5/20090626/',
  creates => '/usr/lib/php5/20090626/ioncube_loader_lin_5.3.so',
  require => Exec['ioncube.extract'],
}

file { 'ioncube.config':
  path    => '/etc/php5/apache2/conf.d/00-ioncube.ini',
  ensure  => present,
  content => "zend_extension=/usr/lib/php5/20090626/ioncube_loader_lin_5.3.so",
  notify  => Service['apache2'],
  require => Exec['ioncube.copy'],
}
