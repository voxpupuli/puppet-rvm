class rvm::passenger::apache(
  $ruby_version,
  $version,
  $rvm_prefix = '/usr/local',
  $mininstances = '1',
  $maxpoolsize = '6',
  $poolidletime = '300'
) {

  if ( versioncmp( $rvm::passenger::apache::version, '4.0.0' ) < 0 ) {
    if ( versioncmp( $rvm::passenger::apache::version, '3.9.0' ) < 0 ) {
      $objdir = 'ext'
    }
    else {
      $objdir = 'libout'
    }
  }
  else {
    $objdir = 'buildout'
  }

  class {
    'rvm::passenger::gem':
      ruby_version => $ruby_version,
      version => $version,
  }

  # TODO: How can we get the gempath automatically using the ruby version
  # Can we read the output of a command into a variable?
  # e.g. $gempath = `usr/local/rvm/bin/rvm ${ruby_version} exec rvm gemdir`
  $gempath = "${rvm_prefix}/rvm/gems/${ruby_version}/gems"
  $binpath = "${rvm_prefix}/rvm/bin/"
  $gemroot = "${gempath}/passenger-${version}"
  $modpath = "${gemroot}/${objdir}/apache2"

  # build the Apache module
  include apache::dev
  exec { 'passenger-install-apache2-module':
    command     => "${rvm::passenger::apache::binpath}rvm ${rvm::passenger::apache::ruby_version} exec passenger-install-apache2-module -a",
    creates     => "${rvm::passenger::apache::modpath}/mod_passenger.so",
    environment => [ 'HOME=/root', ],
    logoutput   => 'on_failure',
    require     => Class['rvm::passenger::gem','apache::dev'],
  }

  class { 'apache::mod::passenger':
    passenger_root           => $gemroot,
    passenger_ruby           => "${rvm_prefix}/rvm/wrappers/${ruby_version}/ruby",
    passenger_max_pool_size  => $maxpoolsize,
    passenger_pool_idle_time => $poolidletime,
    passenger_lib_path       => $modpath,
    passenger_manage_package => false,
    require                  => Exec['passenger-install-apache2-module'],
    subscribe                => Exec['passenger-install-apache2-module'],
  }
}
