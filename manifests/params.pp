# Default module parameters
class rvm::params($manage_group = true) {

  $group = $::operatingsystem ? {
    default => 'rvm',
  }

  $proxy_url = undef
  $no_proxy = undef

  $manage_gpg = $::osfamily ? {
    /(Debian|RedHat)/ => true,
    'Darwin' => false,
    default => false,
  }
  $gpg_key = '409B6B1796C275462A1703113804BB82D39DC0E3'
  $gpg_package = $::osfamily ? {
    /(Debian|RedHat)/ => 'gnupg2',
    default => undef,
  }
}
