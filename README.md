# Debian 13 KDE Post-Install Guide

A simple guide on setting up Debian 13 (Trixie) KDE installation. Covers removing unnecessary default packages, installing NVIDIA proprietary drivers, and replacing Firefox ESR with the official Mozilla build.

---

## Table of Contents

- [Debloat](#debloat)
- [NVIDIA Drivers](#nvidia-drivers)
- [Firefox (Mozilla Repository)](#firefox-mozilla-repository)

---

## Debloat

The debloat script removes a set of packages that ship with Debian 13 KDE by default but are rarely needed, things like Konqueror, Akregator, JuK, Dragon Player, various input method frameworks, and regional fonts. It also runs `autoremove` to pull out orphaned dependencies and cleans up any leftover configuration files from previously removed packages.

Download the debian-13-debloat.sh file and make it executable:

```bash
chmod +x /path/to/script/debian-13-debloat.sh
```

Then run the script(you have to be in the direcotry that the script is located in):

```bash
sudo ./debian-13-debloat.sh
```

The script will:

1. Purge the listed packages (any that are already missing are skipped with a warning rather than aborting)
2. Run `apt-get autoremove --purge` to remove orphaned dependencies
3. Check for and purge residual config files (`rc` state in `dpkg -l`)
4. Run `apt-get clean` to clear the package cache
5. Run `flatpak uninstall --unused` if Flatpak is present on the system

Reboot after it finishes to make sure all removed background services are fully gone.

---

## NVIDIA Drivers

Before installing the NVIDIA driver, the `non-free` and `non-free-firmware` components need to be enabled in your APT sources. Open `/etc/apt/sources.list` and make sure it looks like this:

```
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free non-free-firmware

deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security/ trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security/ trixie-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
```

Then run the following commands in order:

```bash
sudo apt update
sudo apt install linux-headers-generic
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install nvidia-kernel-dkms nvidia-driver nvidia-driver-libs:i386
```

After the installation finishes add these lines to the /etc/modprobe.d/nvidia-options.conf file:

```
options nvidia_drm modeset=1
options nvidia_drm fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
```

Then rebuild the initramfs and reboot:

```bash
sudo update-initramfs -u
sudo systemctl reboot
```

## Firefox (Mozilla Repository)

Debian ships `firefox-esr` by default. This section replaces it with the standard Firefox release build from Mozilla's own APT repository.

**1. Remove the ESR package and install wget:**

```bash
sudo apt purge firefox-esr && sudo apt install wget
```

**2. Import the Mozilla repository signing key:**

```bash
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
```

**3. Add the Mozilla APT repository:**

```bash
sudo tee /etc/apt/sources.list.d/mozilla.sources > /dev/null << EOF
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
```

**4. Pin the Mozilla repository to ensure it takes priority:**

```bash
sudo tee /etc/apt/preferences.d/mozilla > /dev/null << EOF
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
```

**5. Update and install:**

```bash
sudo apt update
sudo apt install firefox
```

If you prefer a different release channel, replace `firefox` with one of: `firefox-esr`, `firefox-beta`, `firefox-nightly`, or `firefox-devedition`.
