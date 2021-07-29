# Default module parameters
class rvm::params ($manage_group = true) {
  $manage_rvmrc = $facts['os']['family'] ? {
    'Windows' => false,
    default   => true
  }

  $group = $facts['os']['name'] ? {
    default => 'rvm',
  }

  $proxy_url = undef
  $no_proxy = undef
  # hkp://keys.gnupg.net was used in the past but doesn't prodive the current key
  # more infos: https://rvm.io/rvm/security
  $key_server = 'hkp://pool.sks-keyservers.net'

  # install the gpg key if gpg is installed or being installed in this puppet run
  if defined(Class['gnupg']) or $facts['gnupg_installed'] {
    $gnupg_key_id = '39499BDB'
  } else {
    $gnupg_key_id = false
  }

  # ignored param, using gnupg module
  $gpg_package = $facts['kernel'] ? {
    /(Linux|Darwin)/ => 'gnupg2',
    default          => undef,
  }
}
