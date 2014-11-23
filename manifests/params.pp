# Default module parameters
class rvm::params() {

  $group = $::operatingsystem ? {
    default => 'rvm',
  }

  $proxy_url = undef

  unless $gpg_package {
    case $::operatingsystem {
      'Ubuntu','Debian': { $gpg_package = 'gnupg2' }
      'CentOS','RedHat','Fedora','rhel','Amazon','Scientific': { $gpg_package = 'gpg2' }
      default: {
        notify { 'rvm install gpg2':
          message => 'Unknown OS type: could not derive package that gpg2 lives in. Please define gpg_package in hiera.yml.', }
      }
    }
  }
}
