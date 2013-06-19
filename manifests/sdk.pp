# == Class: android::sdk
#
# This downloads and unpacks the Android SDK. It also
# installs necessary 32bit libraries for 64bit Linux systems.
#
# === Authors
#
# Etienne Pelletier <epelletier@maestrodev.com>
#
# === Copyright
#
# Copyright 2012 MaestroDev, unless otherwise noted.
#
class android::sdk {
  include android::paths
  include wget

  case $::kernel {
    'Linux': {
      $unpack_command = "/bin/tar -xvf ${android::paths::archive} --no-same-owner --no-same-permissions"
    }
    'Darwin': {
      $unpack_command = "/usr/bin/unzip ${android::paths::archive}"
    }
    default: {
      fail("Unsupported Kernel: ${::kernel} operatingsystem: ${::operatingsystem}")
    }
  }

  file { $android::paths::installdir:
    ensure => directory,
    owner  => $android::user,
    group  => $android::group,
  } ->
  wget::fetch { 'download-androidsdk':
    source      => $android::paths::source,
    destination => $android::paths::archive,
  } ->
  exec { 'unpack-androidsdk':
    command => $unpack_command,
    creates => $android::paths::sdk_home,
    cwd     => $android::paths::installdir,
    user    => $android::user,
  }

  # For 64bit systems, we need to install some 32bit libraries for the SDK
  # to work.
  if ($::kernel == 'Linux') and ($::architecture == 'x86_64' or $::architecture == 'amd64') {
    case $::osfamily {
      'RedHat': {
        # list 64-bit version and use latest for installation too so that the same version is applied to both
        $thirty_two_bit_packages =  [ 'glibc.i686', 'zlib.i686', 'libstdc++.i686', 
                             'zlib', 'libstdc++' ]
      }
      'Debian': {
        $thirty_two_bit_packages =  [ 'ia32-libs' ]
      }
      default : {
        $thirty_two_bit_packages = undef
      }
    }
    if $thirty_two_bit_packages != undef {
      package { $thirty_two_bit_packages:
        ensure => latest,
      }
    }
  }

  case $::kernel {
    'Linux': {
      $sdk_home     = "${android::installdir}/android-sdk-linux"
      file { '/etc/profile.d/android_sdk.sh':
        ensure  => file,
        mode    => '0644',
        content => template("${module_name}/android-sdk.sh.erb"),
      }
    }
    'Darwin': {
      fail('fix me')
    }
    default: {
      fail("Unsupported Kernel: ${::kernel} operatingsystem: ${::operatingsystem}")
     }
   }
}
