require 'spec_helper'

describe 'bitbucket' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os} #{facts}" do
        let(:facts) do
          facts
        end
        context 'with javahome not set' do
          it('fails') do
            is_expected.to raise_error(Puppet::Error, %r{You need to specify a value for javahome})
          end
        end
        context 'with javahome set' do
          let(:params) do
            { javahome: '/opt/java' }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('bitbucket') }
          it { is_expected.to contain_class('bitbucket::params') }
          it { is_expected.to contain_anchor('bitbucket::start').that_comes_before('Class[bitbucket::install]') }
          it { is_expected.to contain_class('bitbucket::install').that_comes_before('Class[bitbucket::config]') }
          it { is_expected.to contain_class('bitbucket::config') }
          it { is_expected.to contain_class('bitbucket::backup') }
          it { is_expected.to contain_class('bitbucket::service').that_subscribes_to('Class[bitbucket::config]') }
          it { is_expected.to contain_anchor('bitbucket::end').that_requires('Class[bitbucket::service]') }
          it { is_expected.to contain_class('archive') }
          it { is_expected.to contain_service('bitbucket') }
        end
      end
    end
  end
  context 'unsupported operating system' do
    describe 'test class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        { osfamily: 'Solaris',
          operatingsystem: 'Nexenta',
          operatingsystemmajrelease: '7' }
      end

      it { expect { is_expected.to contain_service('bitbucket') }.to raise_error(Puppet::Error, %r{Nexenta 7 not supported}) }
    end
  end
end
