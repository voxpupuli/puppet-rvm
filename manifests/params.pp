# Default module parameters
class rvm::params (
  Boolean $manage_group = true,
) {
  $group = 'rvm'

  $proxy_url = undef
  $no_proxy = undef

  $signing_keys = [
    { 'id' => 'D39DC0E3', 'source' => 'https://rvm.io/mpapis.asc' },
    { 'id' => '39499BDB', 'source' => 'https://rvm.io/pkuczynski.asc' },
  ]
}
