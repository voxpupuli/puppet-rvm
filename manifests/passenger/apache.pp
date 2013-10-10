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

  # exclude passenger for $apache::mod_packages
  class { 'apache':
    mod_packages => {
      'auth_kerb'  => 'mod_auth_kerb',
      'fcgid'      => 'mod_fcgid',
      'perl'       => 'mod_perl',
      'php5'       => $distrelease ? {
        '5'     => 'php53',
        default => 'php',
      },
      'proxy_html' => 'mod_proxy_html',
      'python'     => 'mod_python',
      'shibboleth' => 'shibboleth',
      'ssl'        => 'mod_ssl',
      'wsgi'       => 'mod_wsgi',
      'dav_svn'    => 'mod_dav_svn',
      'suphp'      => 'mod_suphp',
      'xsendfile'  => 'mod_xsendfile',
    },
  }

  class { 'apache::mod::passenger':
    passenger_root           => "${gempath}/passenger-${version}",
    passenger_ruby           => "${rvm_prefix}/rvm/wrappers/${ruby_version}/ruby",
    passenger_max_pool_size  => $maxpoolsize,
    passenger_pool_idle_time => $poolidletime,
  }
}
