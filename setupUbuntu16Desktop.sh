#!/bin/bash

# For x220:
# https://pastebin.com/ULpLYjhC

# Todo:

# Add pip install termdown

# DOCKER https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04 
#    perhaps only on some computers
# Get docky settings - github gist?
# Get guake settings - github gist?
# Add nextcloud setup step
# Configuring multiload - broken settings down here
# Seperate out settings changes from desktop setting
# Add weather location changer for widget
# SSH SERVER + keys
# Add guake, docky, etc, to ubuntu startup scripts
# NEEDED ON SOME COMPUTERS (including BY-Thinkpad)

# Add nextcloud setup
# Add config sync system
# Setup guake config
# Look into gnome config
# Dockyconf
# Git repos
# Scripts folder
# http://www.omgubuntu.co.uk/2016/09/wunderline-nifty-command-line-app-wunderlist
# Consider: http://mkchromecast.com/


# get current user, and home directory path
if [ "$USER" == "root" ]; then
  currentUser=$SUDO_USER;
else
  currentUser=$USER;
fi

# Request Sudo Access before we continue further
sudo cat /dev/null


##############
# Settings
##############

# Set to 1 to purge (remove program and settings before install)
aptPurgeBeforeInstall=0;

# destination for papertrail logging
#example:
papertrailDest="logs12345.papertrailapp.com:12345"

0
# Setup log
inslog="/tmp/installlog"; # install log

sudo touch $inslog
sudo chown $currentUser:$currentUser $inslog;

echo "Install Log" > $inslog
echo "" > $inslog
echo "" > $inslog


curStep=""; # current step
function step() {
  curStep="$1"
  echo " [      ] $curStep";
}

function stepdone() {
  echo -en "\e[1A"
  echo -e " [ \e[92mDONE\e[0m ] $curStep"
}

function error() {
  echo -en "\e[1A"
  echo -e " [ \e[33mERR \e[0m ] $curStep"
}

function nothing() {
  echo "";
}


function aptinstall() {
  packageName=$1;
  packageDescription=$2;

  installed=0;

  if [[ $aptPurgeBeforeInstall = 1 ]] ; then
    step "Purging package before inst: '$packageName' "
    sudo dpkg --configure -a > $inslog 2>&1
    sudo apt-get purge -y $packageName > $inslog 2>&1
    nothing;
  fi

#  dpkg-query -l $packageName >/dev/null 2>&1 && installed=1;
#  which $packageName >/dev/null 2>&1 && installed=1;
  sudo dpkg -s $packageName >/dev/null 2>&1 && installed=1;

  if [[ $installed = 0 ]] ; then

    step "Installing package from apt: '$packageName' "

    sudo apt-get install -y $packageName > $inslog 2>&1

    if [[ $? -ne 0 ]] ; then
      sudo dpkg --configure -a > $inslog 2>&1
      sudo apt-get install -y $packageName > $inslog 2>&1

      if [[ $? -ne 0 ]] ; then
        error;
        step "Failed to install from apt:  '$packageName' "
        stepdone;

        return 1;
      fi

    fi

    echo " * $packageName ($packageDescription)" >> $listfile

  else

    step "Already installed from apt:  '$packageName' "

  fi

  stepdone;

}

function aptppaadd() {

  ppaName=$1;

  if ! grep -q "^deb .*$ppaName" /etc/apt/sources.list /etc/apt/sources.list.d/*; then

    step "Adding PPA repo:         '$ppaName'";
    sudo add-apt-repository ppa:$ppaName -y > $inslog 2>&1

  else

    step "PPA repo already added:  '$ppaName'";

  fi

  stepdone;

}

# Delete temp directory after script finishes
# set -e
# function cleanup {
#  echo "Removing temp directory"
#  sudo rm  -rf /tmp/installfiles
# }
# trap cleanup EXIT

# Allow Scroll lock
xmodmap -e 'add mod3 = Scroll_Lock' > $inslog 2>&1


# tempDir="/home/$currentUser/temp"
tempDir="/tmp/installfiles"
homeDir="/home/$currentUser"

# This file contains a list of installed tools for user reference
listfile="$homeDir/installedtools.md"

# Version (unity or MATE)
version=$(grep cdrom: /etc/apt/sources.list | sed -n '1s|.*deb cdrom:\[\([^ ]* *[^ ]*\).*|\1|p');


# Make Temp Directory
sudo mkdir $tempDir -p > $inslog 2>&1
sudo chown $currentUser:$currentUser $tempDir > $inslog 2>&1


function reownHome() {
	chown $currentUser:$currentUser $homeDir -R > $inslog 2>&1
}


# Root Override Section
if [ "$1" != "-f" ] ; then
  if [ "$(whoami)" != "root" ] ; then
      echo "Starting...." > $inslog 2>&1
    else
     echo "Please do not run as root";
     exit 1;
  fi


  #############
  # NONROOT TASKS
  #############

  # Change Desktop

  function getBackgroundFile() {
    mkdir -p $homeDir/Pictures/DesktopBackgrounds> $inslog 2>&1

    filename=$1;> $inslog 2>&1
    desktopBgBaseUrl="https://github.com/benyanke/configScripts/raw/master/img/desktopbackgrounds"> $inslog 2>&1

    rm -r "$homeDir/Pictures/DesktopBackgrounds/$filename" > $inslog 2>&1
    wget "$desktopBgBaseUrl/$filename" -O "$homeDir/Pictures/DesktopBackgrounds/$filename" > $inslog 2>&1
  }



  # Function to set the desktop background
  function setDesktopBackground() {
      basepath="$homeDir/Pictures/DesktopBackgrounds/" > $inslog 2>&1
      desktopfile=$1 > $inslog 2>&1

      # Allow VNC connections over localhost
      gsettings set org.gnome.Vino network-interface lo > $inslog 2>&1

      ##### For MATE only
      if [[ $version == *"MATE"* ]] ; then

          # Change scrolling settings
          gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false > $inslog 2>&1

          # Change desktop background
          gsettings set org.mate.background primary-color "rgb(0,0,0)" > $inslog 2>&1
          gsettings set org.mate.background picture-filename "$basepath/$desktopfile" > $inslog 2>&1

      ##### For Unity only
      else

          # Change scrolling settings
          gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false > $inslog 2>&1

          # Change file manager display to list
          gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' > $inslog 2>&1

          # Change menus to in the window
          gsettings set com.canonical.Unity integrated-menus true > $inslog 2>&1

          # Change desktop background
          gsettings set org.gnome.desktop.background picture-uri "file://$basepath/$desktopfile" > $inslog 2>&1

          # Add menus to windows instead of top of screen
          gsettings set com.canonical.Unity integrated-menus true

          # Change clock setting
          gsettings set com.canonical.indicator.datetime show-day true
          gsettings set com.canonical.indicator.datetime show-date true
          gsettings set com.canonical.indicator.datetime show-week-numbers true


      fi
  }

  # Download files from git repo
  step "Downloading Desktop Backgrounds"
    getBackgroundFile "cat6.jpg" &
    getBackgroundFile "cloud.png" &
    getBackgroundFile "inception-code.jpg" &
    getBackgroundFile "knight.jpg" &
    getBackgroundFile "ubuntu-blue.jpg" &
    getBackgroundFile "ubuntu-grey.jpg" &
    getBackgroundFile "O4GTKkE.jpg" &
    wait;
  stepdone

  # Set one to be the background
  step "Setting desktop background"
  setDesktopBackground "O4GTKkE.jpg";
  stepdone


#  echo ""
#  echo "### Upgrade to root ###"

  # Upgrade to root
  if [ "$(whoami)" != "root" ]; then
      sudo $0 -f
      exit 0;
  else
      error "Could not be upgraded to root.";
      exit 1;
  fi

else # end nonroot tasks, moving on to root


  #############
  # ROOT TASKS
  #############

  # Reown the home dir before continuing
  reownHome



  # Install packages

  # Not sure what this does
#  add-apt-repository ppa:n-muench/programs-ppa -y

  # For good measure
  step "Running dpkg configure";
  sudo dpkg --configure -a > $inslog 2>&1
  stepdone;

  # Get WINE
  aptppaadd "ubuntu-wine/ppa"

  # Get most recent shutter version
#  aptppaadd "shutter/ppa"

  # NextCloud
  aptppaadd "nextcloud-devs/client"

  # Weather widget
  aptppaadd "kasra-mp/ubuntu-indicator-weather"

  # LibreOffice
  aptppaadd "libreoffice/ppa"

  # Get expanded ubuntu list
  aptppaadd "universe"

  # Get RDP/VNC Client
  aptppaadd "remmina-ppa-team/remmina-next"

  # Get nautilus-git extension, "nautilus-git"
  aptppaadd "khurshid-alam/nautilus-git"

  # Get QOwnNotes
  aptppaadd "pbek/qownnotes"

  # Get Adobe Brackets
  aptppaadd "webupd8team/brackets"

  step "Updating APT List"
  apt-get update > $inslog 2>&1
  stepdone

  step "Upgrading APT Packages"
  apt-get upgrade -y > $inslog 2>&1
  apt-get dist-upgrade -y > $inslog 2>&1
  stepdone

  step "Installing APT packages"
  echo "# Tools Installed by Initial Setup Script" > $listfile
  echo "" > $listfile
  stepdone

  step "Updating APT List"
  apt-get update > $inslog 2>&1
  stepdone

  # CLI packages
  echo "## Installed CLI tools" >> $listfile

  aptinstall "virtualenv" "Python virtual environment"
  aptinstall "htop" "Process manager and viewer"
#  aptinstall "lm-sensor" "Fan speed control"
  aptinstall "npm" "NodeJS package manager"
  aptinstall "git" "Version control"
  aptinstall "tree" "Recursive file listing"
  aptinstall "openvpn" "OpenVPN Client"
  aptinstall "jq" "JSON Formatting"
  aptinstall "nmap" "Network mapping tool"
  aptinstall "dconf-tools" "Configuration management tools"
  aptinstall "ufw" "An Uncomplicated Firewall"
  aptinstall "nethogs" "Bandwidth shaping"
  aptinstall "zip" "File packer for .zip files"
  aptinstall "unzip" "File unpacker for .zip files"
  aptinstall "screen" "Terminal multiplexing"
  aptinstall "iperf3" "Bandwidth tracking"
  aptinstall "curl" "HTTP client"
  aptinstall "traceroute" "Does what it says"
  aptinstall "python-pip" "Python package manager"
  aptinstall "byobu" "Alternate terminal"
  aptinstall "iotop" "Disk IO stats"
  aptinstall "sysstat" "System statistics"
  aptinstall "systemtap-sdt-dev"
  aptinstall "latexmk" "LaTeX tool"
  aptinstall "markdown" "Markdown -> HTML conversion"
  aptinstall "iftop" "Network interface tracking"
  aptinstall "espeak" "Text to Speech tool"
  aptinstall "openssh-server" "SSH server"
  aptinstall "wakeonlan" "Wake on lan tool"
  aptinstall "taskwarrior" "Task list and management"
  aptinstall "nfs-common" "NFS mount lib"
  aptinstall "cifs-utils" "CIFS mount lib"
  aptinstall "trash-cli" "Automated trash can management"
  aptinstall "mcrypt" "mcrypt encryption tools"
  aptinstall "xautomation" "X Automation Helper"
  aptinstall "httpie" "API testing tool"
  aptinstall "gnuplot" "Gnu plot"
  aptinstall "fping" "fping"
  aptinstall "nautilus-git" "Nautilus-Git extension"
  aptinstall "qownnotes" "Cloud notepad"
  aptinstall "golang-go" "GO Language tools"
  aptinstall "phantomjs" "A headless CLI browser tool"

#  aptinstall "mc" "Midnight commander"
#  aptinstall "wine" "Windows (non-)emulation tool"
#  aptinstall "winetricks" "Additional tools for WINE"
#  aptinstall "openconnect" "Cisco VPN client"
#  aptinstall "ubuntu-restricted-extras" "Audio tools" # Not sure if needed

  # Install gui packages
  aptinstall "speedcrunch" "SpeedCrunch calculator"
  aptinstall "gimp" "Raster image editing"
  aptinstall "inkscape" "Vector image editing"
  aptinstall "lynx" "Terminal web browser"
  aptinstall "lyx" "Document tool"
  aptinstall "audacity" "Audio editor"
  aptinstall "pdfmod" "PDF editor"
  aptinstall "pdftk" "PDF editor"
  aptinstall "cheese" "Webcam snapshots"
  aptinstall "vlc" "Video and audio viewer"
  aptinstall "sshuttle" "SSH-based pseudo-VPN"
  aptinstall "virt-manager" "KVM desktop management frontend"
  aptinstall "scribus" "Document typesetting"
  aptinstall "network-manager-openvpn" "GUI for OpenVPN"
#  aptinstall "shutter" "Screenshot tool"
  aptinstall "xfce4-screenshooter" "Screenshot tool"
  aptinstall "mysql-workbench" "DBA tool for mySQL/MariaDB"
  aptinstall "xbindkeys" "Hotkey additions"
  aptinstall "xbindkeys-config" "Hotkey tool"
  aptinstall "remmina" "RDP/VNC client"
  aptinstall "remmina-plugin-rdp" "RDP/VNC client"
  aptinstall "libfreerdp-plugins-standard" "RDP/VNC client"
#  aptinstall "idjc" "Internet DJ program" # Causes a hang in the install
  aptinstall "fmit" "Music tuner"
  aptinstall "gconf-editor" "Advanced unity tweaking"
  aptinstall "libreoffice" "LibreOffice"
  aptinstall "ptask" "Task warrior gui frontend"
  aptinstall "kazam" "Screen Recording"
  aptinstall "meld" "File diff gui"
  aptinstall "texmaker" "Tex Tool"
#  aptinstall "patchage" "Virtual audio patchbay"
#  aptinstall "quasmixer" "Virtual audio mixer"
  aptinstall "lm-sensors" "Mixer"
  aptinstall "autossh" "Auto SSH tunnels"

 if [[ $version == *"MATE"* ]] ; then
    # MATE-only things here
    sleep 0.1;
  else
    # Ubuntu unity only things here
    aptinstall "unity-tweak-tool" "Advanced unity tweaking"
  fi

  aptinstall "touchegg" "Multitouch trackpad getures"
  aptinstall "guake" "Guake dropdown terminal"
  aptinstall "indicator-weather" "Top dock widget for weather"
  aptinstall "indicator-multiload" "Top dock widget for system load"
  aptinstall "indicator-cpufreq" "Top dock widget for cpu speed"
  aptinstall "sqlite" "Mini SQL RDMS"
  aptinstall "sqlitebrowser" "Browser for SQLite browser"
  aptinstall "gnome-disk-utility" "GNOME disk formatting and management utility"
  aptinstall "pdfsam" "PDF Split and Merge"
  aptinstall "corebird" "Desktop twitter client"
  aptinstall "docky" "Program dock"
  aptinstall "nextcloud-client" "NextCloud desktop client"
  aptinstall "thunar" "Alternate file manager"
  aptinstall "gtk-recordmydesktop" "Desktop video recording tool"
  aptinstall "xarchiver" "Adds compress and extract to file manager right-click"

#  aptinstall "retext" "Text editor"
#  aptinstall "vino" "VNC server"
#  aptinstall "gnome-todo" "Gnome Todo"
#  aptinstall "gnome-calendar" "Gnome Calendar"

  stepdone


  function setstartup() {
    mkdir $currentUser/.config/autoload -p > $inslog 2>&1
    cp /usr/share/applications/$1.desktop /home/$currentUser/.config/autostart/ > $inslog 2>&1

 #   runuser -l  $currentUser -c `grep '^Exec' /home/$currentUser/.config/autostart/$1.desktop | tail -1 | sed 's/^Exec=//' | sed 's/%.//' | sed 's/^"//g' | sed 's/" *$//g'` &  >/dev/null 2>&1
 #   disown;

  }

  step "Adding startup apps"
  setstartup "guake"
  setstartup "indicator-multiload"
  setstartup "indicator-weather"
  setstartup "nextcloud"
  stepdone

function installdeb() {
  step "Installing $2 from *.deb file"
  deb="$1"
  wget $1 -O $tempDir/$2.deb > $inslog 2>&1

  dpkg --install $tempDir/$2.deb > $inslog 2>&1

  if [ $? != 0 ]; then
    apt-get install -f -y  > $inslog 2>&1
    dpkg --install $tempDir/$2.deb > $inslog 2>&1
  fi

  echo " * $2 ($3)" >> $listfile
  stepdone
}

  step "Installing Chrome Dependencies"
  apt-get install -y libgconf2-4 libnss3-1d libxss1 > $inslog 2>&1
  if [ $? != 0 ]; then
    apt-get install -f -y > $inslog 2>&1
    apt-get install -y libgconf2-4 libnss3-1d libxss1 > $inslog 2>&1
  fi
  stepdone

  installdeb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "Chrome" "Browser"

  # Install Slack
  installdeb "https://downloads.slack-edge.com/linux_releases/slack-desktop-2.3.2-amd64.deb"  "Slack" "Team messaging"

  # Install Atom
  installdeb "https://atom.io/download/deb" "Atom" "Text Editor"


  # TODO: Setup sync with hard-links to NextCloud

  reownHome

  # Enable UFW firewall


  step "Configuring UFW (block all !22)"
  ufw default deny incoming > $inslog 2>&1
  ufw default allow outgoing > $inslog 2>&1
  ufw allow 22 > $inslog 2>&1
  ufw --force enable > $inslog 2>&1
  stepdone

  # Upgrade all packages before finishing
  step "Update and Upgrade All APT Packages Again"
  apt-get update > $inslog 2>&1
  apt-get upgrade -y > $inslog 2>&1
  apt-get dist-upgrade -y > $inslog 2>&1
  stepdone


  step "Configuring multiload"

  gsettings set de.mh21.indicator-multiload.general speed uint16 300 > $inslog 2>&1
  gsettings set de.mh21.indicator-multiload.general width uint16 60 > $inslog 2>&1
  gsettings set de.mh21.indicator-multiload.graphs.disk enabled true > $inslog 2>&1
  gsettings set de.mh21.indicator-multiload.graphs.net enabled true > $inslog 2>&1
  gsettings set de.mh21.indicator-multiload.graphs.swap enabled true > $inslog 2>&1
  gsettings set de.mh21.indicator-multiload.graphs.mem enabled true > $inslog 2>&1
  gsettings set de.mh21.indicator-multiload.graphs.load enabled true > $inslog 2>&1


          # Multiload tool
          dconf write /de/mh21/indicator-multiload/general/speed 500
          dconf write /de/mh21/indicator-multiload/general/width 40
          dconf write /de/mh21/indicator-multiload/general/menu-expressions ['CPU: $(percent(cpu.inuse)), iowait $(percent(cpu.io))', 'Mem: $(size(mem.user)), cache $(size(mem.cached))', 'Net: down $(speed(net.down)), up $(speed(net.up))', 'Swap: $(size(swap.used))', 'Load: $(decimals(load.avg,2))', 'Disk: read $(speed(disk.read)), write $(speed(disk.write))']
          dconf write /de/mh21/indicator-multiload/general/graphs ['cpu', 'mem', 'net', 'swap', 'load', 'disk']
          dconf write /de/mh21/indicator-multiload/general/background-color ambiance:background
          dconf write /de/mh21/indicator-multiload/general/color-scheme ambiance


  stepdone



	step "configuring workspaces"
          # Change workspaces to 3x3 instead of 2x2
          dconf write  /org/compiz/profiles/unity/plugins/core/vsize 3
          dconf write  /org/compiz/profiles/unity/plugins/core/hsize 3
	stepdone

          # Change proxy setting
          # Not needed?
#          gsettings set org.gnome.system.proxy use-same-proxy false


          # http://askubuntu.com/questions/41241/shortcut-to-change-launcher-hide-setting

          # Additional settings changes
          # gconftool-2 --type int --set "/apps/compiz-1/plugins/unityshell/screen0/options/launcher_hide_mode" 2

	step "Configuring guake"
          # Guake settings
          gconftool-2 --set "/apps/guake/keybindings/local/new_tab" --type string "<Control>t"
          gconftool-2 --set "/apps/guake/keybindings/local/toggle_fullscreen" --type string "<Control><Shift>f"
          gconftool-2 --set "/apps/guake/keybindings/global/show_hide" --type string "<Primary>space"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab1" --type string "<Control>1"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab2" --type string "<Control>2"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab3" --type string "<Control>3"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab4" --type string "<Control>4"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab5" --type string "<Control>5"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab6" --type string "<Control>6"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab7" --type string "<Control>7"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab8" --type string "<Control>8"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab9" --type string "<Control>9"
          gconftool-2 --set "/apps/guake/keybindings/local/switch_tab10" --type string "<Control>10"


	stepdone



  # Add new programs to launcher
  reownHome

  exit;



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


fi # end root override

