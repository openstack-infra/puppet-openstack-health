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

  it 'should be idempotent' do
    apply_manifest(api_puppet_module, catch_changes: true)
  end

  describe 'required packages' do
    describe 'os packages' do
      required_packages = [
        package('apache2'),
        package('python-dev'),
        package('gunicorn'),
        package('pip'),
        package('virtualenv'),
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
    end
  end

  describe 'required services' do
    describe 'ports are open and services are reachable' do
      describe port(5000) do
        it { should be_listening }
      end

      describe command('curl http://localhost:5000 --verbose') do
        its(:stdout) { should contain('404') }
      end
    end
  end
end
