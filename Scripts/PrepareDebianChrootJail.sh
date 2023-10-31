#!/bin/bash
########################################################################
# PrepareDebianChrootJail.sh
# Author: Charles Pandian, ProjectGuideline.com
# Script Available at: https://github.com/igs3000/ns-3-Turotials/blob/main/Scripts/PrepareDebianChrootJail.sh
########################################################################
#~ 	Version	Codename Release Year	Status
#
#~ 	12	Bookworm	2023	Stable
#~ 	11	Bullseye		2022	Oldstable
#~ 	10	Buster		2020	Oldoldstable
#~ 	9	Stretch		2019	Extended LTS
#~ 	8	Jessie		2017	Extended LTS
#~ 	7	Wheezy		2013	Obsolete
#~ 	6	Squeeze		2011	Obsolete
#~ 	5	Lenny		2009	Obsolete
#~ 	4	Etch			2007	Obsolete
#~ 	3.1	Sarge		2005	Obsolete
#~ 	3.0	Woody		2002	Obsolete
#~ 	2.2	Potato		2000	Obsolete
#~ 	2.1	Slink		1999	Obsolete
#~ 	2.0	Hamm		1998	Obsolete
#~ 	1.3	Bo			1996	Obsolete
#~ 	1.2	Rex			1995	Obsolete
#~ 	1.1	Buzz			1995	Obsolete

########################################################################
# list of top 5 debian versions
topDistros=("bookworm" "bullseye" "buster" "stretch" "jessie")

# list of architechtures
topArchs=("amd32" "arm32" "amd64" "arm64"  )


# Function to check if a string is in the list
string_in_list() {
  local string_to_check="$1"
  shift
  local string_list=("$@")
  
  for item in "${string_list[@]}"; do
    if [ "$item" == "$string_to_check" ]; then
      return 0  # String found in the list
    fi
  done
  
  return 1  # String not found in the list
}

# Get the number of command line parameters.
num_args=$#

# Check if the expected number of arguments is given.
if [[ $num_args != 2 ]]; then
  echo "Usage: $0 <DistroName> <Arch>"
  echo "example $0 Bookworm amd64"
  exit 1
fi

DebianVersion=$1
Arch=$2


if string_in_list "$DebianVersion" "${topDistros[@]}"; then
  echo "The distro $DebianVersion is a valid distro name"
else
  echo "The distro $DebianVersion is not a valid distro name"
  exit 1
fi

if string_in_list "$Arch" "${topArchs[@]}"; then
  echo "The architecture $Arch is a valid architecture name"
else
  echo "The architecture $Arch is not a valid architecture name"
  exit 1
fi

########################################################################
#Step 0: Update apt repositories

sudo apt update

########################################################################
#Step 1: Install the dependencies

sudo apt install binutils debootstrap

# Step 2: Create a directory for holding the root file system (of the guest OS -Debian). 
# It will creating a folder under your current directory where you want to setup chroot jail
# 
# Important Note: This script may work correctly upto last four or fiver versions. 
#                           So we hereby restrict it to install only the recent 5 versions
#                           For older versions we may need to change the repository to a old one
#                            and add them in the topDistros list



chrootFolder="Debian-$DebianVersion-$Arch"

# Check if the directory exists
if [ -d "$chrootFolder" ]; then
  echo "The chrool jail directory  ~/$chrootFolder exists; Skipping installation"
  #exit 1
else
  echo "The directory $chrootFolder does not exist; Creating chroot jail directory: ~/$chrootFolder" 
  mkdir ~/$chrootFolder
fi


echo "Downloading the root file system of $DebianVersion under the folder $chrootFolder"
echo "Please wait for a few minutes with respect to the speed of your internet connection"

########################################################################
#Step 3: Download the entire directory structure of Debian Linux under the folder using debootstrap command
#This will download a few hundred megabytes depending upon the distro of choice. 
#So it will complete the download with respect to your internet speed

sudo debootstrap --arch=$Arch $DebianVersion ~/$chrootFolder http://deb.debian.org/debian


########################################################################
#Step 4: Create a chroot jail Startup Script and set it runnable by the user

cat << EOF > ~/chrootjail$chrootFolder.sh
export DISPLAY=:0.0
xhost +

cd ~/$chrootFolder
sudo mount -t proc /proc proc/
sudo mount -t sysfs /sys sys/

sudo mount --rbind /dev dev/
sudo mount --make-rslave ./dev

#enter in to chroot jail shell
sudo chroot ./

#run the following in host shell on exit from chroot jail
sudo umount -n ./proc
sudo umount -n ./sys

sudo umount -R ./dev
EOF

chmod +x  ~/chrootjail$chrootFolder.sh
########################################################################
echo  "A new chroot Jail was set in the folder $chrootFolder"
echo  "Now you may find a shell script chrootjail$chrootFolder.sh that will automatically set the environment and bring a new chroot Jail of  Debian  $DebianVersion-$Arch "
echo  "You can now execute the script chrootjail$chrootFolder.sh  from a file browser or a terminal"
