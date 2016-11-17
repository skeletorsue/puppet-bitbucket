# == Class: bitbucket::install
#
# This installs the bitbucket module. See README.md for details
#
class bitbucket::install(
  $webappdir,
  $version        = $bitbucket::version,
  $product        = $bitbucket::product,
  $format         = $bitbucket::format,
  $installdir     = $bitbucket::installdir,
  $homedir        = $bitbucket::homedir,
  $manage_usr_grp = $bitbucket::manage_usr_grp,
  $user           = $bitbucket::user,
  $group          = $bitbucket::group,
  $uid            = $bitbucket::uid,
  $gid            = $bitbucket::gid,
  $download_url   = $bitbucket::download_url,
  $deploy_module  = $bitbucket::deploy_module,
  $dburl          = $bitbucket::dburl,
  $checksum       = $bitbucket::checksum,
  ) {

  include '::archive'

  if $manage_usr_grp {
    #Manage the group in the module
    group { $group:
      ensure => present,
      gid    => $gid,
    }
    #Manage the user in the module
    user { $user:
      comment          => 'Bitbucket daemon account',
      shell            => '/bin/bash',
      home             => $homedir,
      password         => '*',
      password_min_age => '0',
      password_max_age => '99999',
      managehome       => true,
      uid              => $uid,
      gid              => $gid,
    }
  }

  if ! defined(File[$installdir]) {
    file { $installdir:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
    }
  }

  # Deploy files using either staging or deploy modules.
  $file = "atlassian-${product}-${version}.${format}"

  if ! defined(File[$webappdir]) {
    file { $webappdir:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
    }
  }

  case $deploy_module {
    'staging': {
      require ::staging
      staging::file { $file:
        source  => "${download_url}/${file}",
        timeout => 1800,
      } ->
      staging::extract { $file:
        target  => $webappdir,
        creates => "${webappdir}/conf",
        strip   => 1,
        user    => $user,
        group   => $group,
        notify  => Exec["chown_${webappdir}"],
        before  => File[$homedir],
        require => [
          File[$installdir],
          File[$webappdir],
          User[$user],
        ],
      }
    }
    'archive': {
      archive { "/tmp/${file}":
        ensure          => present,
        extract         => true,
        extract_command => 'tar xfz %s --strip-components=1',
        extract_path    => $webappdir,
        source          => "${download_url}/${file}",
        creates         => "${webappdir}/conf",
        cleanup         => true,
        checksum_type   => 'md5',
        checksum        => $checksum,
        user            => $user,
        group           => $group,
        before          => File[$homedir],
        require         => [
          File[$installdir],
          File[$webappdir],
          User[$user],
        ],
      }
    }
    default: {
      fail('deploy_module parameter must equal "archive" or staging""')
    }
  }

  file { $homedir:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    require => User[$user],
  } ->

  exec { "chown_${webappdir}":
    command     => "/bin/chown -R ${user}:${group} ${webappdir}",
    refreshonly => true,
    subscribe   => [ User[$user], File[$webappdir] ],
  }

}
