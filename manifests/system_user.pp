define rvm::system_user (
  $create = true,
  $manage_group = true) {

  include rvm::params

  if $create {
    ensure_resource('user', $name, {'ensure' => 'present' })
    User[$name] -> Exec["rvm-system-user-${name}"]
  }

  if $manage_group {
    include rvm::group
    Group[$rvm::params::group] -> Exec["rvm-system-user-${name}"]
  }

  $add_to_group = $::osfamily ? {
    'Darwin' => "/usr/sbin/dseditgroup -o edit -a ${name} -t user ${rvm::params::group}",
    default  => "/usr/sbin/usermod -a -G ${rvm::params::group} ${name}",
  }
  $check_in_group = $::osfamily ? {
    'Darwin' => "/usr/bin/dsmemberutil checkmembership -U ${name} -G ${rvm::params::group} | grep -q 'user is a member'",
    default  => "/bin/cat /etc/group | grep '^${rvm::params::group}:' | grep -qw ${name}",
  }
  exec { "rvm-system-user-${name}":
    command => $add_to_group,
    unless  => $check_in_group,
  }
}
