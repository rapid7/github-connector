Development LDAP Server
=======================

The code in this directory uses OpenLDAP to emulate the Active
Directory records needed for this application to work.  This is
helpful in development and testing if you do not want to connect
to a real Active Directory server.

## Install prerequisites

### Ubuntu

Install OpenLDAP's slapd:

    sudo apt-get install slapd ldap-utils

You may also need to put apparmor into complain mode:

    sudo apt-get install apparmor-utils
    sudo aa-complain /usr/sbin/slapd

### OSX

OpenLDAP is installed on OSX by default.  There is nothing else
you need to do.

## Run test server

To run the server:

    ./run-server

## Accounts

Several accounts are available:

* hsimpson - Normal account
* msimpson - Locked account
* bsimpson - Disabled account
* lsimpson - Password expired

All accounts use password 123456.
