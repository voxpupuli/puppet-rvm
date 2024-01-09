# frozen_string_literal: true

require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  install_puppet_module_via_pmt_on(host, 'puppet-epel', '>= 3.0.1 < 4.0.0') if fact_on(host, 'os.family') == 'RedHat'
  install_puppet_module_via_pmt_on(host, 'puppetlabs-apache', '>= 5.7.0 < 7.0.0')
  install_puppet_module_via_pmt_on(host, 'puppetlabs-java', '>= 6.3.0 < 8.0.0')
end
