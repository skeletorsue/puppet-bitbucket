# == Class: bitbucket::facts
#
# Class to add some facts for bitbucket. They have been added as an external fact
# because we do not want to distrubute these facts to all systems.
#
# === Parameters
#
# [*port*]
#   port that bitbucket listens on.
# [*uri*]
#   ip that bitbucket is listening on, defaults to localhost.
#
# === Examples
#
# class { 'bitbucket::facts': }
#
class bitbucket::facts(
  $ensure        = 'present',
  $port          = '7990',
  $uri           = '127.0.0.1',
  $context_path  = $bitbucket::context_path,
  $json_packages = $bitbucket::params::json_packages,
) inherits bitbucket {

  # Puppet Enterprise supplies its own ruby version if your using it.
  # A modern ruby version is required to run the executable fact
  if $::puppetversion =~ /Puppet Enterprise/ {
    $ruby_bin = '/opt/puppet/bin/ruby'
    $dir      = 'puppetlabs/'
  } else {
    $ruby_bin = '/usr/bin/env ruby'
    $dir      = ''
  }

  if ! defined(File["/etc/${dir}facter"]) {
    file { "/etc/${dir}facter":
      ensure  => directory,
    }
  }
  if ! defined(File["/etc/${dir}facter/facts.d"]) {
    file { "/etc/${dir}facter/facts.d":
      ensure  => directory,
    }
  }

  if $::osfamily == 'RedHat' and $::puppetversion !~ /Puppet Enterprise/ {
    package { $json_packages:
      ensure => present,
    }
  }

  file { "/etc/${dir}facter/facts.d/bitbucket_facts.rb":
    ensure  => $ensure,
    content => template('bitbucket/facts.rb.erb'),
    mode    => '0500',
  }

}
