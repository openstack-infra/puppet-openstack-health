require 'spec_helper_acceptance'

describe 'puppet-openstack-health module', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def default_puppet_module
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(default_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(default_puppet_module, catch_changes: true)
  end

  describe 'required packages' do
    describe 'os packages' do
      required_packages = [
        package('python-dev'),
        package('nodejs'),
        package('npm'),
      ]

      required_packages.each do |package|
        describe package do
          it { should be_installed }
        end
      end
    end

    describe 'npm packages' do
      describe package('gulp') do
        it { should be_installed.by('npm') }
      end
    end
  end

  describe 'required files' do
    describe file('/opt/openstack-health') do
      it { should be_directory }
    end
  end

  describe 'required services' do
    describe service('openstack-health-api') do
      it { should be_running }
      it { should be_enabled }
    end

    describe service('openstack-health-frontend') do
      it { should be_running }
      it { should be_enabled }
    end

    describe 'ports are open and services are reachable' do
      listening_ports = [
        port(5000),
        port(3000),
        port(3001),
      ]

      listening_ports.each do |port|
        describe port do
          it { should be_listening }
        end
      end
    end
  end
end
