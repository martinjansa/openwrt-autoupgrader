# OpenWrt automatic upgrades of firmware and packages

This repository contains a set of scripts that can help you keep your OpenWRT router always up to date by automatic performing of the firmware and/or packages upgrades.

## Brief technical description

All the upgrade script run directly from the router specifically from the /usr/local/sbin/openwrt-autoupgrader.sh and use the configuration file /usr/local/etc/openwrt-autoupgrader. From the security reasons we tipically don't want to open the access from the router to other machines, which implies that the scrip itself cannot perform the backup of the router configuration to other machine before the upgrade and the backups need to be done in other way.

The upgrade script checks the availability of the new upgrade, if a newer version of the firmware is found (compared to the data in the /etc/openwrt_release), downloads it to the /tmp, performs the firmware upgrade and installation of the custom packages (TODO: not done yet).

The detection of the available version and upgrade binary package uses cross-checks of the information from two different web pages
(list of hardware table and hardware data page) to make sure we are really downloading and applying the intended firmware package.
The checksum of the downloaded bin file is compared to the checksum listed in the directory listing on the OpenWrt site.

## Configuration and deployment

Prerequisities:

1) you have a linux-based machine (let's refer it bellow as workstation)

2) the user account from the workstation machine can SSH to the router

    To verify run following command that should open the console on the:

    ```bash
    ssh root@192.168.1.1
    ```

3) Wget with SSL support installed on the router

    The OpenWrt pages are SSL secured and redirect the HTTP traffic to HTTPS, so the only way to download the binaries is via the secure
    protocol, which is the only reasonable way nowadays anyway.

    ```bash
    opkg update
    opkg install wget
    opkg install libustream-openssl
    opkg install ca-certificates
    ```

    See more at: https://wiki.openwrt.org/doc/howto/wget-ssl-certs

Steps:

1) clone this repository on the workstation machine. The root directory of the cloned repo will be later referred as **{git_repo}**.

2) copy the configuration files **{git_repo}/config/default/openwrt-autoupgrader** and **{git_repo}/config/default/deploy** into the folder **{git_repo}/config/private/** under the same names openwrt-autoupgrader and deploy. The files {git_repo/config/private/openwrt-autoupgrader is deployed to the router and {git_repo}/config/private/deploy configures the deployement scrit. These files are ignored by git, so modifying them does not cause the changes in the repository.

3) modify the configuration file {git_repo}/config/private/openwrt-autoupgrader. WARNING: please be extremely carefull here as specifying a wrong version of the HW will most likely cause your router to be bricked.

4) modify the configuration file {git_repo}/config/private/deploy.

5) run **make deploy** from the {git_repo}/ folder to deploy the upgrader files into the router.

    ```bash
    make deploy
    ```

6) Now your are ready to run the autoupgrader in several ways. You are use it either manually from your workstation, configure it into the cron on the router or run it from cron from other computer (your workstation or other server). See the following chapter for details.

## Usage

### Automated upgrades started daily from the router cron

Add following three lines into the /etc/crontab to run the automated upgrades daily at 01:30 - 01:45. Please note the times reserved for the duration of the individual operations:
    
    ```
    30 1 * * * root /usr/local/sbin/openwrt-autoupgrader.sh upgrade_firmware
    40 1 * * * root /usr/local/sbin/openwrt-autoupgrader.sh install_extra_packages
    45 1 * * * root /usr/local/sbin/openwrt-autoupgrader.sh upgrade_packages
    ```

### Automated upgrades started daily remotely from other machine

If you want to run the upgrades in one block, minimize the time the extra packages are not running after the firmware upgrade, log the progress or output or monitor the potential failures, you can use the cron on the other system to run the remote automated upgrades. The example bellow runs daily upgrades at 01:30.

    ```
    30 1 * * * root /usr/local/sbin/openwrt-autoupgrader-remote-upgrade.sh root@192.168.1.1
    ```

Note: you can run the router backup right before the upgrade from the same cron.

### Manual running of the remote router upgrade

You can use this to test and debug the automated upgrades configuration.

1) connect to the router via the SSH and run the upgrade of the OpenWrt firmware

    ```bash
    # connect to the router (use your router's IP address)
    ssh root@192.168.1.1

    # run the firmware upgrade
    /usr/local/sbin/openwrt-autoupgrader.sh upgrade_firmware

    # Note: if the firmware is upgraded, router restarts here
    ```

2) In case of upgrade, wait for the router to restart (use ping to monitor router) and the re-connect to the router via the SSH and re-install the extra OPKG packages and upgrade the all OPKG packages via:

    ```bash
    # connect to the router (use your router's IP address)
    ssh root@192.168.1.1

    # re-install the extra OPLG packages after the firmware upgrade
    /usr/local/sbin/openwrt-autoupgrader.sh install_extra_packages

    # upgrade the OPKG packages
    /usr/local/sbin/openwrt-autoupgrader.sh upgrade_packages
    ```
