# Default module parameters
class rvm::params ($manage_group = true) {
  $group = $facts['os']['name'] ? {
    default => 'rvm',
  }

  $proxy_url = undef
  $no_proxy = undef

  $signing_keys = [
    { 'id' => 'D39DC0E3', 'source' => 'https://rvm.io/mpapis.asc' },
    { 'id' => '39499BDB', 'source' => 'https://rvm.io/pkuczynski.asc' },
  ]
}
