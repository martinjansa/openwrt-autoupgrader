# OpenWrt automatic upgrades of firmware and packages

This repository contains a set of scripts that can help you keep your OpenWRT router always up to date by automatic performing of the firmware and/or packages upgrades.

## Brief technical description

All the upgrade script run directly from the router specifically from the /usr/local/sbin/openwrt-autoupgrader.sh and use the configuration file /usr/local/etc/openwrt-autoupgrader. From the security reasons we tipically don't want to open the access from the router to other machines, which implies that the scrip itself cannot perform the backup of the router configuration to other machine before the upgrade and the backups need to be done in other way.

The upgrade script checks the availability of the new upgrade (TODO: so far hardcoded), if a newer version of the firmware is found (compared to the data in the /etc/openwrt_release), downloads it to the /tmp, performs the firmware upgrade and installation of the custom packages (TODO: not done yet).

## Configuration and deployment

Prerequisities:

1) you have a linux-based machine (let's refer it bellow as workstation)

2) the user account from the workstation machine can SSH to the router

    To verify run following command that should open the console on the:

    ```bash
    ssh root@192.168.1.1
    ```

Steps:

1) clone this repository on the workstation machine. The root directory of the cloned repo will be later referred as **{git_repo}**.

2) copy the configuration files **{git_repo}/config/default/openwrt-autoupgrader** and **{git_repo}/config/default/deploy** into the folder **{git_repo}/config/private/** under the same names openwrt-autoupgrader and deploy. The files {git_repo}/config/private/openwrt-autoupgrader is deployed to the router and {git_repo}/config/private/deploy configures the deployement scrit. These files are ignored by git, so modifying them does not cause the changes in the repository.

3) modify the configuration file {git_repo}/config/private/openwrt-autoupgrader. WARNING: please be extremely carefull here as specifying a wrong version of the HW will most likely cause your router to be bricked.

4) modify the configuration file {git_repo}/config/private/deploy.

5) run **make deploy** from the {git_repo}/ folder to deploy the upgrader files into the router.

    ```bash
    make deploy
    ```

6) connect to the router via the and run the upgrade of the OpenWrt firmware

    ```bash
    # connect to the router (use your router's IP address)
    ssh root@192.168.1.1

    # run the firmware upgrade
    /usr/local/sbin/openwrt-autoupgrader.sh upgrade_firmware

    # Note: if the firmware is upgraded, router restarts here
    ```
