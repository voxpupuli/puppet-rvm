# Install the RVM system
class rvm::system (
  $version=undef,
  $install_from=undef,
  $proxy_url=undef,
  $no_proxy=undef,
  $home=$facts['root_home'],
  Array[Hash[String[1], String[1]]] $signing_keys = $rvm::params::signing_keys,
) inherits rvm::params {
  $actual_version = $version ? {
    undef     => 'latest',
    'present' => 'latest',
    default   => $version,
  }

  # curl needs to be installed
  if ! defined(Package['curl']) {
    case $facts['kernel'] {
      'Linux': {
        ensure_packages(['curl'])
        Package['curl'] -> Exec['system-rvm']
      }
      default: {}
    }
  }

  $http_proxy_environment = $proxy_url ? {
    undef   => [],
    default => ["http_proxy=${proxy_url}", "https_proxy=${proxy_url}"]
  }
  $no_proxy_environment = $no_proxy ? {
    undef   => [],
    default => ["no_proxy=${no_proxy}"]
  }
  $proxy_environment = concat($http_proxy_environment, $no_proxy_environment)
  $environment = concat($proxy_environment, ["HOME=${home}"])

  if $signing_keys {
    include gnupg

    # https keys are downloaded with wget
    ensure_packages(['wget'])
    $signing_keys.each |Hash[String[1], String[1]] $key| {
      gnupg_key { $key['id']:
        ensure     => 'present',
        user       => 'root',
        key_id     => $key['id'],
        key_source => $key['source'],
        key_type   => public,
        before     => Exec['system-rvm'],
        require    => Class['gnupg'],
      }
    }
  }

  if $install_from {
    file { '/tmp/rvm':
      ensure => directory,
    }

    exec { 'unpack-rvm':
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      command => "tar --strip-components=1 -xzf ${install_from}",
      cwd     => '/tmp/rvm',
    }

    exec { 'system-rvm':
      path        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      command     => './install --auto-dotfiles',
      cwd         => '/tmp/rvm',
      creates     => '/usr/local/rvm/bin/rvm',
      environment => $environment,
    }
  }
  else {
    exec { 'system-rvm':
      path        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      command     => "curl -fsSL https://get.rvm.io | bash -s -- --version ${actual_version}",
      creates     => '/usr/local/rvm/bin/rvm',
      environment => $environment,
    }
  }

  # the fact won't work until rvm is installed before puppet starts
  if $facts['rvm_version'] and !empty($facts['rvm_version']) {
    if ($version != undef) and ($version != present) and ($version != $facts['rvm_version']) {
      $signing_keys.each |Hash[String[1], String[1]] $key| {
        Gnupg_key[$key['id']] -> Exec['system-rvm-get']
      }

      # Update the rvm installation to the version specified
      notify { 'rvm-get_version':
        message => "RVM updating from version ${facts['rvm_version']} to ${version}",
      }
      -> exec { 'system-rvm-get':
        path        => '/usr/local/rvm/bin:/usr/bin:/usr/sbin:/bin',
        command     => "rvm get ${version}",
        before      => Exec['system-rvm'], # so it doesn't run after being installed the first time
        environment => $environment,
      }
    }
  }
}
