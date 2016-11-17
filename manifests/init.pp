# == Class: bitbucket
#
# This modules installs Atlassian bitbucket.
#
class bitbucket(

  # JVM Settings
  $javahome     = undef,
  $jvm_xms      = '256m',
  $jvm_xmx      = '1024m',
  $jvm_permgen  = '256m',
  $jvm_optional = '-XX:-HeapDumpOnOutOfMemoryError',
  $jvm_support_recommended_args = '',
  $java_opts    = '',

  # Bitbucket Settings
  $version      = '3.7.0',
  $product      = 'bitbucket',
  $format       = 'tar.gz',
  $installdir   = '/opt/bitbucket',
  $homedir      = '/home/bitbucket',
  $context_path = '',
  $tomcat_port  = 7990,

  # User and Group Management Settings
  $manage_usr_grp = true,
  $user           = 'bitbucket',
  $group          = 'bitbucket',
  $uid            = undef,
  $gid            = undef,

  # Bitbucket 3.8 initialization configurations
  $display_name  = 'bitbucket',
  $base_url      = "https://${::fqdn}",
  $license       = '',
  $sysadmin_username = 'admin',
  $sysadmin_password = 'bitbucket',
  $sysadmin_name  = 'Bitbucket Admin',
  $sysadmin_email = '',
  $config_properties = {},

  # Database Settings
  $dbuser       = 'bitbucket',
  $dbpassword   = 'password',
  $dburl        = 'jdbc:postgresql://localhost:5432/bitbucket',
  $dbdriver     = 'org.postgresql.Driver',

  # Misc Settings
  $download_url = 'http://www.atlassian.com/software/bitbucket/downloads/binary/',
  $checksum     = undef,

  # Backup Settings
  $backup_ensure          = 'present',
  $backupclient_url       = 'https://maven.atlassian.com/public/com/atlassian/bitbucket/backup/bitbucket-backup-distribution',
  $backupclient_version   = '1.9.1',
  $backup_home            = '/opt/bitbucket-backup',
  $backupuser             = 'admin',
  $backuppass             = 'password',
  $backup_schedule_hour   = '5',
  $backup_schedule_minute = '0',
  $backup_keep_age        = '4w',

  # Manage service
  $service_manage = true,
  $service_ensure = running,
  $service_enable = true,

  # Reverse https proxy
  $proxy = {},

  # Command to stop bitbucket in preparation to updgrade. # This is configurable
  # incase the bitbucket service is managed outside of puppet. eg: using the
  # puppetlabs-corosync module: 'crm resource stop bitbucket && sleep 15'
  $stop_bitbucket = 'service bitbucket stop && sleep 15',

  # Choose whether to use puppet-staging, or puppet-archive
  $deploy_module = 'archive',

) {

  validate_hash($config_properties)

  include ::bitbucket::params

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  $webappdir    = "${installdir}/atlassian-${product}-${version}"

  if $::bitbucket_version {
    # If the running version of bitbucket is less than the expected version of bitbucket
    # Shut it down in preparation for upgrade.
    if versioncmp($version, $::bitbucket_version) > 0 {
      notify { 'Attempting to upgrade bitbucket': }
      exec { $stop_bitbucket: }
      if versioncmp($version, '3.2.0') > 0 {
        exec { "rm -f ${homedir}/bitbucket-config.properties": }
      }
    }
  }

  if $javahome == undef {
    fail('You need to specify a value for javahome')
  }

  anchor { 'bitbucket::start': } ->
  class { '::bitbucket::install': webappdir => $webappdir, } ->
  class { '::bitbucket::config': } ~>
  class { '::bitbucket::service': } ->
  class { '::bitbucket::backup': } ->
  anchor { 'bitbucket::end': }
}
