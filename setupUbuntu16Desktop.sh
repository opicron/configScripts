#!/bin/bash


if [ "$EUID" -ne 0 ]
  then
  echo "Starting...."
  else
   echo "Please do not run as root"
fi

#CHANGE THESE

# destination for papertrail logging
#example: 
papertrailDest="logs12345.papertrailapp.com:12345"


# get current user, and home directory path
currentUser=$SUDO_USER
tempDir="/home/$currentUser/temp"
homeDir="/home/$currentUser"

mkdir $tempDir -p


function reownHome() {
	chown benyanke:benyanke $homeDir -R
}


#############
# NONROOT TASKS
#############

# Change Desktop

rm $tempDir/desktop.jpg -r
wget https://raw.githubusercontent.com/benyanke/configScripts/master/img/knightkneeling.jpg -O $tempDir/desktop.jpg

reownHome

# Change desktop background
gsettings set org.gnome.desktop.background picture-uri "file://$tempDir/desktop.jpg"

# Change menus to in the window
gsettings set com.canonical.Unity integrated-menus true

# Change scrolling settings
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

# Change file manager display to list
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

#############
# ROOT TASKS
#############

echo ""
echo "### Upgrade to root ###"

# Upgrade to root
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi

# Install packages
add-apt-repository ppa:n-muench/programs-ppa
add-apt-repository ppa:ubuntu-wine/ppa -y
add-apt-repository universe -y
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y


# CLI packages
apt-get install -y htop git tree openvpn jq nmap dconf-tools ufw wine winetricks mc nethogs zip unzip screen iperf3 curl traceroute python-pip openconnect
echo "### Installed CLI tools ###" > $homeDir/installedTools
echo " - htop (process manager)" >> $homeDir/installedTools
echo " - git (version control)" >> $homeDir/installedTools
echo " - openvpn (vpn)" >> $homeDir/installedTools
echo " - tree (directory structure viewer)" >> $homeDir/installedTools
echo " - jq (json formatter)" >> $homeDir/installedTools
echo " - nmap (network mapping tool)" >> $homeDir/installedTools
echo " - Wine (Windows API)" >> $homeDir/installedTools
echo " - Midnight Commander (CLI File Manager)" >> $homeDir/installedTools
echo " - NetHogs (HTOP for Network Connections)" >> $homeDir/installedTools
echo " - Zip and Unzip (.zip file handlers)" >> $homeDir/installedTools
echo " - Screen (Terminal abstraction)" >> $homeDir/installedTools
echo " - iperf3 (Bandwidth tester)" >> $homeDir/installedTools
echo " - traceroute (network path tester)" >> $homeDir/installedTools
echo " - PIP  (python packman)" >> $homeDir/installedTools
echo " - OpenConnect  (UWW VPN)" >> $homeDir/installedTools
echo "" >> $homeDir/installedTools

# Install gui packages
apt-get install -y inkscape gimp lyx audacity filezilla pdfmod cheese vlc sshuttle musescore virtualbox virt-manager scribus network-manager-openvpn shutter guake mysql-workbench retext xbindkeys xbindkeys-config remmina idjc
echo "### Installed GUI tools ###" >> $homeDir/installedTools
echo " - Inkscape (Vector Graphics)" >> $homeDir/installedTools
echo " - GIMP (Raster Graphics)" >> $homeDir/installedTools
echo " - LyX (LaTeX tool)" >> $homeDir/installedTools
echo " - Audacity (Audio editor)" >> $homeDir/installedTools
echo " - FileZilla (FTP and SFTP client)" >> $homeDir/installedTools
echo " - Cheese (Camera viewer)" >> $homeDir/installedTools
echo " - VLC (Media viewer)" >> $homeDir/installedTools
echo " - MuseScore (Music Engraving)" >> $homeDir/installedTools
echo " - Eclipse (Development)" >> $homeDir/installedTools
echo " - Virtualbox (VMs)" >> $homeDir/installedTools
echo " - Virt Manager (KVM remote tool)" >> $homeDir/installedTools
echo " - Scribus (Desktop typesetting)" >> $homeDir/installedTools
echo " - OpenVPN Network Manager Integration (GUI control for OpenVpn)" >> $homeDir/installedTools
echo " - Shutter (advanced screenshots)" >> $homeDir/installedTools
echo " - guake (advanced terminal)" >> $homeDir/installedTools
echo " - mySQL Workbench (a mysql development tool)" >> $homeDir/installedTools
echo " - ReText (markdown editor)" >> $homeDir/installedTools
echo " - XBindKeys (X server keystroke customizer)" >> $homeDir/installedTools
echo " - Remmina (RDP)" >> $homeDir/installedTools
echo " - Internet DJ Console" >> $homeDir/installedTools

# Install Chrome
apt-get install -y libgconf2-4 libnss3-1d libxss1
if [ $? != 0 ]; then
  apt-get install -f -y;
  apt-get install -y libgconf2-4 libnss3-1d libxss1
fi

rm  $tempDir/chrome.deb -f
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O $tempDir/chrome.deb

dpkg --install $tempDir/chrome.deb

if [ $? != 0 ]; then
  apt-get install -f -y;
  dpkg --install $tempDir/chrome.deb;
fi

echo " - Chrome (Browser)" >> $homeDir/installedTools


# Install Dropbox
# No longer using, keeping code here in case I ever choose to revert

# rm  $tempDir/dropbox.deb -f
# wget https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2015.10.28_amd64.deb -O $tempDir/dropbox.deb

# dpkg --install $tempDir/dropbox.deb

# if [ $? != 0 ]; then
#   apt-get install -f -y;
#   dpkg --install $tempDir/dropbox.deb;
# fi

# restart nautilus
# nautilus -q && nautilus &

# echo " - Dropbox (File Sync)" >> $homeDir/installedTools


# Install OwnCloud
curl http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_16.04/Release.key > /tmp/owncloud-release.key

apt-key add - < /tmp/owncloud-release.key
rm /tmp/owncloud-release.key -f

sh -c "echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_16.04/ /' > /etc/apt/sources.list.d/owncloud-client.list"
apt-get update
# apt-get install owncloud-client -y 
apt-get install owncloud-client -y --allow-unauthenticated

echo " - OwnCloud (File Sync)" >> $homeDir/installedTools

# add update features
wget http://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_16.04/Release.key -O $tempDir/oc.key
sudo apt-key add - < $tempDir/oc.key
rm $tempdir/oc.key -f


# Setup sync with hard-links to NextCloud
# mkdir /home/

reownHome

# Enable UFW firewall

ufw default deny incoming
ufw default allow outgoing
ufw allow 22
ufw --force enable


# Upgrade all packages before finishing
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# Add new programs to launcher
exit;

myfile='firefox.desktop'
list=`gsettings get com.canonical.Unity.Launcher favorites`
newlist=`echo $list | sed s/]/", '${myfile}']"/`
gsettings set com.canonical.Unity.Launcher favorites "$newlist"
su $currentUser -c "unity --replace"

reownHome


#Add to papertrail
# If computer uses rsyslog
if [ -a /etc/rsyslog.conf ]; then
# if it doesn't already contain papertrail logging
 if ! grep -q $papertrailDest "/etc/rsyslog.conf"; then
    echo "" >> /etc/rsyslog.conf
    echo "*.*          @$papertrailDest" >> /etc/rsyslog.conf
    service rsyslog restart
  fi
fi

