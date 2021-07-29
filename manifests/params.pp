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
  $key_server = 'hkp://keys.gnupg.net'

  # sadly the gpg module is ages old and doesn't support long key ids
  $gnupg_key_id = [
    { 'id' => 'D39DC0E3', 'source' => 'https://rvm.io/mpapis.asc' },
    { 'id' => '39499BDB', 'source' => 'https://rvm.io/pkuczynski.asc' },
  ]

  # ignored param, using gnupg module
  $gpg_package = $facts['kernel'] ? {
    /(Linux|Darwin)/ => 'gnupg2',
    default          => undef,
  }
}
