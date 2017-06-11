require 'spec_helper_acceptance'

describe 'puppet-openstack_health::api manifest', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def frontend_puppet_module
    module_path = File.join(pp_path, 'frontend.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(frontend_puppet_module, catch_failures: true)
  end

  describe 'required services' do
    describe 'ports are open and services are reachable' do
      describe port(80) do
        it { should be_listening }
      end

      describe command('curl http://localhost --verbose') do
        its(:stdout) { should contain('OpenStack Health') }
      end
    end
  end
end
