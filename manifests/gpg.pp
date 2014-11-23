# RVM's GPG key security signing mechanism requires gpg2 for key import / validation

class rvm::gpg() inherits rvm::params {
  ensure_packages([$rvm::params::gpg_package])
}
