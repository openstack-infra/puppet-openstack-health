require 'spec_helper_acceptance'

describe 'puppet-openstack_health::api manifest', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def api_puppet_module
    module_path = File.join(pp_path, 'api.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(api_puppet_module, catch_failures: true)
  end

  describe 'required packages' do
    describe 'os packages' do
      required_packages = [
        package('apache2'),
        package('python-dev'),
        package('python-pip'),
        package('python-virtualenv'),
      ]

      required_packages.each do |package|
        describe package do
          it { should be_installed }
        end
      end
    end
  end

  describe 'required files' do
    describe file('/opt/openstack-health') do
      it { should be_directory }
      it { should be_owned_by 'openstack_health' }
      it { should be_grouped_into 'openstack_health' }
    end

    describe file('/etc/openstack-health.conf') do
      it { should be_file }
      it { should be_owned_by 'openstack_health' }
      it { should be_grouped_into 'openstack_health' }
      its(:content) { should contain 'db_uri' }
      its(:content) { should contain 'ignored_run_metadata_keys' }
      its(:content) { should contain 'build_change' }
      its(:content) { should contain 'build_zuul_url' }
    end
  end

  describe 'required services' do
    describe 'ports are open and services are reachable' do
      describe port(5000) do
        it { should be_listening }
      end

      describe command('curl http://localhost:5000/status --verbose') do
        its(:stdout) { should contain('status') }
        its(:stdout) { should contain('true') }
        its(:stdout) { should_not contain('false') }
      end
    end
  end
end
