# frozen_string_literal: true

require 'spec_helper_acceptance'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'rvm' do
  # host variables
  let(:osfamily) { fact('osfamily') }
  let(:osname) { fact('operatingsystem') }
  let(:osversion) { fact('operatingsystemrelease') }

  # rvm config
  let(:rvm_path) { '/usr/local/rvm/' }

  # list of currently supported interpreters
  # https://github.com/rvm/rvm/blob/master/config/known

  # ruby 2.7 config
  let(:ruby27_version) { 'ruby-2.7.0' } # chosen for RVM binary support across nodesets
  let(:ruby27_environment) { "#{rvm_path}environments/#{ruby27_version}" }
  let(:ruby27_bin) { "#{rvm_path}rubies/#{ruby27_version}/bin/" }
  let(:ruby27_gems) { "#{rvm_path}gems/#{ruby27_version}/gems/" }
  let(:ruby27_gemset) { 'myproject' }
  let(:ruby27_and_gemset) { "#{ruby27_version}@#{ruby27_gemset}" }

  # ruby 2.6 config
  let(:ruby26_version) { 'ruby-2.6.5' } # chosen for RVM binary support across nodesets
  let(:ruby26_environment) { "#{rvm_path}environments/#{ruby26_version}" }
  let(:ruby26_bin) { "#{rvm_path}rubies/#{ruby26_version}/bin/" }
  let(:ruby26_gems) { "#{rvm_path}gems/#{ruby26_version}/gems/" }
  let(:ruby26_gemset) { 'myproject' }
  let(:ruby26_and_gemset) { "#{ruby26_version}@#{ruby26_gemset}" }

  # passenger baseline configuration
  let(:service_name) do
    case osfamily
    when 'Debian'
      'apache2'
    when 'RedHat'
      'httpd'
    end
  end
  let(:mod_dir) do
    case osfamily
    when 'Debian'
      '/etc/apache2/mods-available/'
    when 'RedHat'
      '/etc/httpd/conf.d/'
    end
  end
  let(:rackapp_user) do
    case osfamily
    when 'Debian'
      'www-data'
    when 'RedHat'
      'apache'
    end
  end
  let(:rackapp_group) do
    case osfamily
    when 'Debian'
      'www-data'
    when 'RedHat'
      'apache'
    end
  end
  let(:conf_file) { "#{mod_dir}passenger.conf" }
  let(:load_file) { "#{mod_dir}passenger.load" }

  # baseline manifest
  let(:manifest) do
    <<-EOS
      if $::osfamily == 'RedHat' {
        class { 'epel':
          before => Class['rvm'],
        }
      }

      class { 'rvm': }
      -> rvm::system_user { 'vagrant': }
    EOS
  end

  it 'rvm should install and configure system user' do
    # Run it twice and test for idempotency
    apply_manifest(manifest, catch_failures: true)
    apply_manifest(manifest, catch_changes: true)
    shell('/usr/local/rvm/bin/rvm list') do |r|
      expect(r.stdout).to include('# No rvm rubies installed yet.')
      expect(r.exit_code).to be_zero
    end
  end

  context 'when installing rubies' do
    let(:manifest) do
      super() + <<-EOS
        rvm_system_ruby {
          '#{ruby27_version}':
            ensure      => 'present',
            default_use => false;
          '#{ruby26_version}':
            ensure      => 'present',
            default_use => false;
        }
      EOS
    end

    it 'installs with no errors' do
      apply_manifest(manifest, catch_failures: true)
      apply_manifest(manifest, catch_changes: true)
    end

    it 'reflects installed rubies' do
      shell('/usr/local/rvm/bin/rvm list') do |r|
        expect(r.stdout).to include(ruby27_version).and include(ruby26_version)
        expect(r.exit_code).to be_zero
      end
    end

    context 'and installing gems' do
      let(:gem_name) { 'simple-rss' } # used because has no dependencies
      let(:gem_version) { '1.3.1' }

      let(:gemset_manifest) do
        manifest + <<-EOS
          rvm_gemset {
            '#{ruby27_and_gemset}':
              ensure  => present,
              require => Rvm_system_ruby['#{ruby27_version}'];
          }
          rvm_gem {
            '#{ruby27_and_gemset}/#{gem_name}':
              ensure  => '#{gem_version}',
              require => Rvm_gemset['#{ruby27_and_gemset}'];
          }
          rvm_gemset {
            '#{ruby26_and_gemset}':
              ensure  => present,
              require => Rvm_system_ruby['#{ruby26_version}'];
          }
          rvm_gem {
            '#{ruby26_and_gemset}/#{gem_name}':
              ensure  => '#{gem_version}',
              require => Rvm_gemset['#{ruby26_and_gemset}'];
          }
        EOS
      end

      it 'installs with no errors' do
        apply_manifest(gemset_manifest, catch_failures: true)
        apply_manifest(gemset_manifest, catch_changes: true)
      end

      it 'reflects installed gems and gemsets' do
        shell("/usr/local/rvm/bin/rvm #{ruby27_version} gemset list") do |r|
          expect(r.stdout).to include("\n=> (default)").and include("\n   global").and include("\n   #{ruby27_gemset}")
          expect(r.exit_code).to be_zero
        end

        shell("/usr/local/rvm/bin/rvm #{ruby26_version} gemset list") do |r|
          expect(r.stdout).to include("\n=> (default)").and include("\n   global").and include("\n   #{ruby26_gemset}")
          expect(r.exit_code).to be_zero
        end
      end
    end
  end

  context 'when installing jruby' do
    let(:jruby_version) { 'jruby' }

    let(:manifest) do
      super() + <<-EOS
        class { 'java': }
        -> rvm_system_ruby { '#{jruby_version}':
          ensure      => 'present',
          default_use => false;
        }
      EOS
    end

    it 'installs with no errors' do
      apply_manifest(manifest, catch_failures: true)
      apply_manifest(manifest, catch_changes: true)
    end

    it 'reflects installed rubies' do
      shell('/usr/local/rvm/bin/rvm list') do |r|
        expect(r.stdout).to include(jruby_version)
        expect(r.exit_code).to be_zero
      end
    end
  end

  # TODO: fails to build on CentOS 8
  context 'when installing passenger 6.0.x', unless: fact('os.name') == 'CentOS' && fact('os.release.major') == '8' do
    let(:passenger_version) { '6.0.9' }
    let(:passenger_domain) { 'passenger3.example.com' }

    let(:passenger_ruby) { "#{rvm_path}wrappers/#{ruby27_version}/ruby" }
    let(:passenger_root) { "#{ruby27_gems}passenger-#{passenger_version}" }
    # particular to 3.0.x (may or may not also work with 2.x?)
    let(:passenger_module_path) { "#{passenger_root}/ext/apache2/mod_passenger.so" }

    let(:manifest) do
      super() + <<-EOS
        rvm_system_ruby {
          '#{ruby27_version}':
            ensure      => 'present',
            default_use => false,
        }
        class { 'apache':
          service_enable => false, # otherwise detects changes in 2nd run in ubuntu and docker
        }
        class { 'rvm::passenger::apache':
          version            => '#{passenger_version}',
          ruby_version       => '#{ruby27_version}',
          mininstances       => '3',
          maxinstancesperapp => '0',
          maxpoolsize        => '30',
          spawnmethod        => 'smart-lv2',
        }
        /* a simple ruby rack 'hello world' app */
        file { '/var/www/passenger':
          ensure  => directory,
          owner   => '#{rackapp_user}',
          group   => '#{rackapp_group}',
          require => Class['rvm::passenger::apache'],
        }
        file { '/var/www/passenger/config.ru':
          ensure  => file,
          owner   => '#{rackapp_user}',
          group   => '#{rackapp_group}',
          content => "app = proc { |env| [200, { \\"Content-Type\\" => \\"text/html\\" }, [\\"hello <b>world</b>\\"]] }\\nrun app",
          require => File['/var/www/passenger'] ,
        }
        apache::vhost { '#{passenger_domain}':
          port    => '80',
          docroot => '/var/www/passenger/public',
          docroot_group => '#{rackapp_group}' ,
          docroot_owner => '#{rackapp_user}' ,
          custom_fragment => "PassengerRuby  #{passenger_ruby}\\nRailsEnv  development" ,
          default_vhost => true ,
          require => File['/var/www/passenger/config.ru'] ,
        }
      EOS
    end

    it 'installs with no errors' do
      # Run it twice and test for idempotency
      apply_manifest(manifest, catch_failures: true)
      apply_manifest(manifest, catch_changes: true)

      expect(shell("/usr/local/rvm/bin/rvm #{ruby27_version} do #{ruby27_bin}gem list passenger | grep \"passenger (#{passenger_version})\"").exit_code).to be_zero
    end

    it 'is running' do
      service(service_name) do |s|
        expect(s).to be_enabled.and be_running
      end
    end

    it 'answers' do
      shell('/usr/bin/curl localhost:80') do |r|
        expect(r.stdout).to include('hello <b>world</b>')
        expect(r.exit_code).to be_zero
      end
    end

    # this works only on legacy passenger, which we only have on CentOS 7
    it 'outputs status via passenger-status', if: fact('operatingsystemrelease').to_i == 7 do
      shell("rvmsudo_secure_path=1 /usr/local/rvm/bin/rvm #{ruby27_version} do passenger-status") do |r|
        expect(r.stdout).to include('General information')
        expect(r.exit_code).to be_zero
      end
    end

    it 'module loading should be configured as expected' do
      file(load_file) do |f|
        expect(f).to contain "LoadModule passenger_module #{passenger_module_path}"
      end
    end

    it 'module behavior should be configured as expected' do
      file(conf_file) do |f|
        expect(f).to contain("PassengerRoot \"#{passenger_root}\"").and contain("PassengerRuby \"#{passenger_ruby}\"")
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
