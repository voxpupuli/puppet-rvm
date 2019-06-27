# RVM's GPG key import
class rvm::gnupg_key(
  $key_id     = $rvm::params::gnupg_key_id,
  $key_source = $rvm::params::key_source,
) inherits rvm::params {

  gnupg_key { "rvm_${key_id}":
    ensure     => present,
    key_id     => $key_id,
    user       => 'root',
    key_source => $key_source,
    key_type   => public,
  }

}
