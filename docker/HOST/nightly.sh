#!/bin/sh
# Wait for other tasks to finish
while [[ -f /tmp/running-tasks ]] ; do
   sleep 10 ;
done

# Get this script folder path
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"


# Create monthly email body, add title and current date
# -----------------------------------------------------
install -b -m 750 /dev/null ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nMONTHLY HOUSEKEEPING TASKS\n" >> ${SCRIPTDIR}/logs/monthly.txt
date >> ${SCRIPTDIR}/logs/monthly.txt


# CLEANUP - OS, local apps, user profile 
# --------------------------------------
sudo bleachbit --preset --clean |& tee -a ${SCRIPTDIR}/logs/bleachbit.tmp
# Add the summary of Bleachbit output to our monthly mail
echo -e "\BLEACHBIT - Cleanup of OS, local apps and user profile..\n" >> ${SCRIPTDIR}/logs/monthly.txt
tail -n 4 ${SCRIPTDIR}/logs/bleachbit.tmp >> ${SCRIPTDIR}/logs/monthly.txt
sudo rm ${SCRIPTDIR}/logs/bleachbit.tmp

# CLEANUP - unused docker images and volumes 
# ----------------------------------------
echo -e "\nCLEANUP of unused docker images..\n" >> ${SCRIPTDIR}/logs/monthly.txt
docker image prune -a -f |& tee -a ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nCLEANUP of unused docker volumes..\n" >> ${SCRIPTDIR}/logs/monthly.txt
docker volume prune -f |& tee -a ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nFor a full cleanup, remember to regularly run this command after verifying all your containers are running: docker system prune --all --volumes -f\n" >> ${SCRIPTDIR}/logs/monthly.txt


# Check docker registry for image updates and send notifications
# --------------------------------------------------------------
sudo diun


# Run btrfs scrub monthly
# -----------------------
echo -e "\nScrub btrfs filesystems..\n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/nvme1n1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdd |& tee -a ${SCRIPTDIR}/logs/monthly.txt

# Run btrfs balance monthly, first 10% data, then try 20%
# -------------------------
echo -e "\nBalance btrfs filesystems in 2 runs each.. \n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 / |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 / |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /mnt/disks/data0 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /mnt/disks/data0 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /mnt/disks/data1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /mnt/disks/data1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /mnt/disks/data2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /mnt/disks/data2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt


# Send email
# ---------------------------------
s-nail -s "Obelix Server - monthly housekeeping" < ${SCRIPTDIR}/logs/monthly.txt default


# Append email to monthly logfile and delete email
# ------------------------------------------------
touch ${SCRIPTDIR}/logs/monthly.log
sudo cat ${SCRIPTDIR}/logs/monthly.txt >> ${SCRIPTDIR}/logs/monthly.log
rm ${SCRIPTDIR}/logs/monthly.txt
