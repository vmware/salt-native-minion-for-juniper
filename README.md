# salt-native-minion-juniper

## Overview

Salt Native Minion for Juniper was originally developed on GitLab
Here are the instructions for GitLab, but in final releases, the Salt Native
Minion for Juniper was built using a bash script.

## Getting started

To make it easy for you to get started with GitLab, here's a list of recommended next steps.

## Add your files

- [ ] [Create](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#create-a-file) or [upload](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#upload-a-file) files
- [ ] [Add files using the command line](https://docs.gitlab.com/ee/gitlab-basics/add-file.html#add-a-file-using-the-command-line) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin https://gitlab.com/saltstack/open/salt-native-minion-junos.git
git branch -M main
git push -uf origin main
```

## Integrate with your tools

- [ ] [Set up project integrations](https://gitlab.com/saltstack/open/salt-native-minion-junos/-/settings/integrations)

## Collaborate with your team

- [ ] [Invite team members and collaborators](https://docs.gitlab.com/ee/user/project/members/)
- [ ] [Create a new merge request](https://docs.gitlab.com/ee/user/project/merge_requests/creating_merge_requests.html)
- [ ] [Automatically close issues from merge requests](https://docs.gitlab.com/ee/user/project/issues/managing_issues.html#closing-issues-automatically)
- [ ] [Enable merge request approvals](https://docs.gitlab.com/ee/user/project/merge_requests/approvals/)
- [ ] [Automatically merge when pipeline succeeds](https://docs.gitlab.com/ee/user/project/merge_requests/merge_when_pipeline_succeeds.html)

## Test and Deploy

Use the built-in continuous integration in GitLab.

- [ ] [Get started with GitLab CI/CD](https://docs.gitlab.com/ee/ci/quick_start/index.html)
- [ ] [Analyze your code for known vulnerabilities with Static Application Security Testing(SAST)](https://docs.gitlab.com/ee/user/application_security/sast/)
- [ ] [Deploy to Kubernetes, Amazon EC2, or Amazon ECS using Auto Deploy](https://docs.gitlab.com/ee/topics/autodevops/requirements.html)
- [ ] [Use pull-based deployments for improved Kubernetes management](https://docs.gitlab.com/ee/user/clusters/agent/)
- [ ] [Set up protected environments](https://docs.gitlab.com/ee/ci/environments/protected_environments.html)

## Name

Salt support for Juniper

## Description

This project allows you to build support for Salt on Juniper QFX and MX Intel-based routers.

Provided is a .gitlab-ci.yml file to utilise GitLab CI/CD

The CI/CD file generates a Juniper tarball package which can be installed and removed with Juniper tools on QFX and MX.

Documation on Salt 3005.1 for Juniper can be found here:

    https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/juniper.html


## Installation

### Before installing the Juniper native minion:

Check that your network device and firmware are supported. See Juniper for more information.
Ensure that ports 4505 and 4506 are open on the applicable Juniper switches or routers.
Salt uses ports 4505 and 4506 for outbound communication from the master to the minions. The Juniper native minion uses a direct connection to the Juniper switch or router and uses the Management Interface on the switch/router for communication. For that reason, ports 4505 and 4506 need to be open on the appropriate Management Interfaces.

### Installation

Juniper network devices run Junos OS, which includes the Junos CLI. When connecting to a Juniper network device, you start at the OS-level. To run commands within Junos OS command-line interface (CLI), you need to first run the CLI command. All examples used are for Salt 3005.1.

#### Shell pre-configuration

Before you can install the Juniper native minion, you need to set up your shell pre-configuration:

1. Run the following command within the shell:

.. code-block::

    mkdir -p /var/local/salt/etc

2. Save the following configuration in /var/local/salt/etc/proxy:

.. code-block::

    master: <ip of salt master>
    proxy:
      proxytype: junos
      host: localhost

    beacon:
      beacons:
        junos_rre_keys:
          -  interval:
               43200

    ping_interval: 2

    loop_interval: 1

    enable_fqdns_grains: False

Note: You may also use the standard configuration commands for Salt if needed.

#### Proxy pre-configuration

The beacons portion of the configuration is needed on routing platforms with dual Routing Engines. The beacon configuration ensures the following directories and files are copied to the backup Routing Engine:

    +---------------------------+-----------------------------------------------------------+
    |      Directory	        | Description                                               |
    +===========================+===========================================================+
    | /var/local/salt/etc/pki   | The directory where the master and minion keys reside.    |
    |                           | If the Routing Engine master changes, the master still    |
    |                           | recognizes the new Routing Engine due to configuration    |
    |                           | existing by both Routing Engines.                         |
    +---------------------------+-----------------------------------------------------------+
    | /var/local/salt/etc/proxy	| Copying this file to the backup Routing Engine ensures    |
    |                           | that the same configuration exists in both Routing Engines|
    |                           | without additional steps needed on the network device.    |
    +---------------------------+-----------------------------------------------------------+

The interval property is defined in a measurement of seconds, dictating how often files are copied to the backup Routing Engine.

Note: When the Juniper native minion is installed, log rotation for the native minion log file */var/log/salt/proxy* is automatically installed with:

*   A limit of 7 compressed files.
*   Log rotation if the log file exceeds 200 KB.

#### CLI pre-configuration

1. Run the following commands within the CLI at the edit prompt:

.. code-block::

    edit
    set system services ssh root-login allow
    set system services netconf ssh
    set system extensions providers saltstack license-type customer deployment-scope commercial

2. To confirm these commands were successful, run:

.. code-block::

    show system extensions providers

3. This command provides an expected output of:

.. code-block::

    saltstack {
      license-type customer deployment-scope commercial;
    }

3. If the command was successful, commit the changes with:

.. code-block::

    commit


#### Juniper native minion installation and configuration

1. Download, verify, and transfer the Juniper installation files (prior to community-support this was repo.saltproject.io). The Juniper package is a tarball, extension *tgz*.

2. Run the following commands within the CLI at the edit prompt:

.. code-block::

    run request system software add /var/tmp/<salt-native-minion>.tgz
    exit

3. Edit the */var/local/salt/etc/salt/proxy* file to update the minion configuration with your environment’s specific details, such as the master’s IP address, the minion ID, etc.

4. (Optional): If your router does not have the ability to use Reverse DNS lookup to obtain the Fully Qualified Domain Name (fqdn) for an IP Address, check the enable_fqdns_grains setting in the minion configuration file, */etc/salt/minion* and ensure it is *False* instead. For example:

.. code-block::

    enable_fqdns_grains: False

Note: On a regular salt-minion this setting is defaulted to *True*, but for native minions the setting has been defaulted to *False*. This setting, if *True*, allows all IP addresses to be processed with underlying calls to socket.gethostbyaddr. These calls can take up to 5 seconds to be released after reaching socket.timeout. During that time, there is no fqdn for that IP address. Although calls to socket.gethostbyaddr are processed asynchronously, the calls still add 5 seconds every time grains are generated if an IP does not resolve.  Hence the reason to default the setting to False on native minions, some of which can be used on routers.

5. In the */var/local/salt/etc/salt/proxy* configuration file, change the following settings to:

.. code-block::

    ping_interval: 2
    loop_interval: 1

Installing the Juniper native minion:

* Creates /var/db/scripts/commit/salt.slax
* Creates /var/db/scripts/event/salt_event.py
* Creates /var/db/scripts/op/salt_dualrengine.slax
* Creates /var/db/scripts/event/salt_log.slax
* Creates a backup in the */config/SaltBackup* directory. This backup is referenced during native minion upgrades
* Configures: *saltstack* super-user event-options SALT_POLICY and *salt_event.py* event script and *salt.slax* commit script. Copies these scripts to the other dual routing engine (if it exists) and configures log rotation of */var/log/salt/proxy* automatically

#### Enabling and starting Salt as a service

The next step in the installation process is to enable and start Salt as a service on the Juniper native minion:

1. Run the following commands within the CLI at the edit prompt:

.. code-block::

    set system extensions extension-service application file salt-junos arguments minion daemonize

2. To confirm these commands were successful, run:

.. code-block::

    show system extensions extension-service

This command provides an expected output of:

.. code-block::

    application {
      file salt-junos {
        arguments minion;
        daemonize;
      }
    }

3. If the command was successful, commit the changes with:

.. code-block::

    commit

#### Verifying the installation

A running native minion will typically have three processes running salt-junos. To check the initial health of the new installation:

1. Run the following command within the CLI at the edit prompt:

.. code-block::

    show system processes extensive| match salt

This command provides a similar output to:

.. code-block::

    57858 - I 0:00.00 /var/run/scripts/jet/salt-junos minion
    57859 - I 0:00.49 /var/run/scripts/jet/salt-junos minion
    57861 - S 0:39.39 /var/run/scripts/jet/salt-junos minion

2. To retrieve the local native minion version, run the following within the CLI:

.. code-block::

    show version | match salt

Depending on the version output, the resulting output is similar to the following format:

.. code-block::

    Salt Minion 3005.1 for JUNOS [20221010-211222]

3. To see the super-user created by, and used to manage, the native minion:

.. code-block::

    show configuration system login user saltstack


#### Post-installation

Once the key for the Juniper network device has been accepted by your master, Salt can be used to manage the native minion. To validate that Salt is managing the minion, run some basic Salt commands to retrieve baseline information:

.. code-block::

    salt <juniper-target> test.ping
    salt <juniper-target> test.version

Note: To use the Junos Automation Enhancements, you must install the software bundle that contains Enhanced Automation. See Running Junos OS with Enhanced Automation.

#### Starting and stopping the Juniper native minion

After installation, you can disable (start) and enable (stop) the Juniper native minion using the following commands from the edit prompt:

.. code-block::

    deactivate system extensions extension-service application file salt-junos
    commit

To restart the Juniper native minion, use the following commands from the edit prompt:

.. code-block::

    activate system extensions extension-service application file salt-junos
    commit

## Creating a Tiamat utilising tgz JET based package

To create a Juniper package for Juniper which utilises Tiamat, the GitLab CI/CD pipeline currently does all the work, utilizing a FreeBSD 10.2 VM, however this was to ensure sufficient version compatibility, newer versions of FreeBSD 11.x should work too, depending on the version of Juniper routers which you desire to support.  The older the version of Juniper router, the older the version of FreeBSD that is required.

To create a tgz JET based package for Juniper which utilises Tiamat

Steps:

1. Checkout Juniper's JetEZ - Easy SDK  and apply it's contents to the *jetez* sub-directory (see Additional references)
2. Obtain manifest.certs and third-party keys from Juniper if desire to run on Juniper hardware (all built software requires signing in order to run on Juniper hardware)
3. Create tiamat build on 64-bit build machines
4. Create 64-bit JET package
5. Push to tarball to storage location for later use


## Contributing

Salt support on Juniper is a community-run project and open to all contributions
The salt-native-minion-for-juniper project team welcomes contributions from the
community. Before you start working with salt-native-minion-for-juniper, please
read our [Developer Certificate of Origin](https://cla.vmware.com/dco).
All contributions to this repository must be signed as described on that page.
Your signature certifies that you wrote the patch or have the right to pass it
on as an open-source patch. For more detailed information,
refer to [CONTRIBUTING.md](CONTRIBUTING.md).

The regular Open Source methods of contributing to a project apply:

*   Fork the project
*   Make your modifications to your fork
*   Provide tests for your modifications
*   Submit Merge/Pull Request to the project
*   Adjust modifications as per Reviewers of Merge/Pull Request

### Additional references

For Junos OS specific modules that can be used against Junos native minions from a master, refer to the following:

* Junos OS Execution Module https://docs.saltproject.io/en/master/ref/modules/all/salt.modules.junos.html
* Junos OS State Modules https://docs.saltproject.io/en/master/ref/states/all/salt.states.junos.html
* Junos OS Grains https://docs.saltproject.io/en/master/ref/grains/all/salt.grains.junos.html

Additional documentation endpoints for reference:

* JetEZ reference docs https://www.juniper.net/documentation/product/us/en/juniper-extension-toolkit/
* PyEZ reference docs https://www.juniper.net/documentation/product/us/en/junos-pyez/
* JetEZ - Easy SDK https://github.com/Juniper/jetez


## Authors and acknowledgment

The initial work in porting Salt for the Juniper platform was done by David Murphy damurphy@vmware.com and C.R. Oldham coldham@vmware.com

## License

Apache License 2.0

## Project status

The Salt native minion for Juniper is now a community project.  In the past, VMware through Salt Project supported and developed Salt for Juniper, but VMware has now turned over on-going development to the community.

The project is currently seeking volunteers to step in as a maintainer or owner, to allow the project to keep going.
