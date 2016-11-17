require 'spec_helper.rb'

describe 'bitbucket' do
  describe 'bitbucket::backup' do
    context 'supported operating systems' do
      on_supported_os.each do |os, facts|
        context "on #{os} #{facts}" do
          let(:facts) do
            facts
          end

          context 'install bitbucket backup client with default params' do
            let(:params) do
              { javahome: '/opt/java' }
            end
            it 'deploys bitbucket backup client 1.9.1 from tar.gz' do
              is_expected.to contain_archive("/tmp/bitbucket-backup-distribution-#{BACKUP_VERSION}.tar.gz").
                with('source'       => "https://maven.atlassian.com/public/com/atlassian/bitbucket/backup/bitbucket-backup-distribution/#{BACKUP_VERSION}/bitbucket-backup-distribution-#{BACKUP_VERSION}.tar.gz",
                     'extract_path' => "/opt/bitbucket-backup/bitbucket-backup-client-#{BACKUP_VERSION}",
                     'creates'      => "/opt/bitbucket-backup/bitbucket-backup-client-#{BACKUP_VERSION}/lib",
                     'user'         => 'bitbucket',
                     'group'        => 'bitbucket')
            end

            it 'manages the bitbucket-backup directories' do
              is_expected.to contain_file('/opt/bitbucket-backup').
                with('ensure' => 'directory',
                     'owner'  => 'bitbucket',
                     'group'  => 'bitbucket')
              is_expected.to contain_file("/opt/bitbucket-backup/bitbucket-backup-client-#{BACKUP_VERSION}").
                with('ensure' => 'directory',
                     'owner'  => 'bitbucket',
                     'group'  => 'bitbucket')

              is_expected.to contain_file('/opt/bitbucket-backup/archives').
                with('ensure' => 'directory',
                     'owner'  => 'bitbucket',
                     'group'  => 'bitbucket')
            end
            it 'manages the backup cron job' do
              is_expected.to contain_cron('Backup Bitbucket').
                with('ensure'  => 'present',
                     'command' => "/opt/java/bin/java -Dbitbucket.password=\"password\" -Dbitbucket.user=\"admin\" -Dbitbucket.baseUrl=\"http://localhost:7990\" -Dbitbucket.home=/home/bitbucket -Dbackup.home=/opt/bitbucket-backup/archives -jar /opt/bitbucket-backup/bitbucket-backup-client-#{BACKUP_VERSION}/bitbucket-backup-client.jar",
                     'user'    => 'bitbucket',
                     'hour'    => '5',
                     'minute'  => '0')
            end
            it 'removes old archives' do
              is_expected.to contain_tidy('remove_old_archives').
                with('path'    => '/opt/bitbucket-backup/archives',
                     'age'     => '4w',
                     'matches' => '*.tar',
                     'type'    => 'mtime',
                     'recurse' => 2)
            end
          end

          context 'should contain custom java path' do
            let(:params) do
              { javahome: '/usr/local/java' }
            end
            it do
              is_expected.to contain_class('bitbucket').with_javahome('/usr/local/java')
              is_expected.to contain_cron('Backup Bitbucket').
                with('command' => "/usr/local/java/bin/java -Dbitbucket.password=\"password\" -Dbitbucket.user=\"admin\" -Dbitbucket.baseUrl=\"http://localhost:7990\" -Dbitbucket.home=/home/bitbucket -Dbackup.home=/opt/bitbucket-backup/archives -jar /opt/bitbucket-backup/bitbucket-backup-client-#{BACKUP_VERSION}/bitbucket-backup-client.jar")
            end
          end

          context 'should contain custom backup client version' do
            let(:params) do
              {
                javahome: '/opt/java',
                backupclient_version: '99.43.111'
              }
            end
            it do
              is_expected.to contain_archive('/tmp/bitbucket-backup-distribution-99.43.111.tar.gz').
                with('source' => 'https://maven.atlassian.com/public/com/atlassian/bitbucket/backup/bitbucket-backup-distribution/99.43.111/bitbucket-backup-distribution-99.43.111.tar.gz',
                     'extract_path' => '/opt/bitbucket-backup/bitbucket-backup-client-99.43.111',
                     'creates' => '/opt/bitbucket-backup/bitbucket-backup-client-99.43.111/lib',
                     'user' => 'bitbucket',
                     'group' => 'bitbucket')
              is_expected.to contain_file('/opt/bitbucket-backup/bitbucket-backup-client-99.43.111').
                with('ensure' => 'directory',
                     'owner'  => 'bitbucket',
                     'group'  => 'bitbucket')
              is_expected.to contain_cron('Backup Bitbucket').with('command' => '/opt/java/bin/java -Dbitbucket.password="password" -Dbitbucket.user="admin" -Dbitbucket.baseUrl="http://localhost:7990" -Dbitbucket.home=/home/bitbucket -Dbackup.home=/opt/bitbucket-backup/archives -jar /opt/bitbucket-backup/bitbucket-backup-client-99.43.111/bitbucket-backup-client.jar')
            end
          end

          context 'should contain custom backup home' do
            let(:params) do
              {
                javahome: '/opt/java',
                backup_home: '/my/backup'
              }
            end
            it do
              is_expected.to contain_class('bitbucket').with_backup_home(%r{my/backup})
              is_expected.to contain_file('/my/backup/archives').
                with('ensure' => 'directory',
                     'owner'  => 'bitbucket',
                     'group'  => 'bitbucket')
              is_expected.to contain_cron('Backup Bitbucket').with('command' => "/opt/java/bin/java -Dbitbucket.password=\"password\" -Dbitbucket.user=\"admin\" -Dbitbucket.baseUrl=\"http://localhost:7990\" -Dbitbucket.home=/home/bitbucket -Dbackup.home=/my/backup/archives -jar /my/backup/bitbucket-backup-client-#{BACKUP_VERSION}/bitbucket-backup-client.jar")
            end
          end

          context 'should contain custom backup user and password' do
            let(:params) do
              {
                javahome: '/opt/java',
                backupuser: 'myuser',
                backuppass: 'mypass'
              }
            end
            it do
              is_expected.to contain_class('bitbucket').with_backupuser('myuser').with_backuppass('mypass')
              is_expected.to contain_cron('Backup Bitbucket').
                with('command' => "/opt/java/bin/java -Dbitbucket.password=\"mypass\" -Dbitbucket.user=\"myuser\" -Dbitbucket.baseUrl=\"http://localhost:7990\" -Dbitbucket.home=/home/bitbucket -Dbackup.home=/opt/bitbucket-backup/archives -jar /opt/bitbucket-backup/bitbucket-backup-client-#{BACKUP_VERSION}/bitbucket-backup-client.jar")
            end
          end

          context 'should remove old archives' do
            let(:params) do
              {
                javahome: '/opt/java',
                backup_keep_age: '1y',
                backup_home: '/my/backup'
              }
            end
            it do
              is_expected.to contain_tidy('remove_old_archives').
                with('path' => '/my/backup/archives',
                     'age' => '1y')
            end
          end
        end
      end
    end
  end
end
