#!/usr/bin/env bash
# Build an ARM64 Windows Vagrant box for VirtualBox (Apple Silicon) from an ISO,
# using an Autounattend.xml on a secondary virtual DVD.
#
# Usage: tools/build-box.sh <iso> <box-name> [image-index] [disk-gb] [memory-mb]
#   tools/build-box.sh ~/Downloads/<server-arm64>.ISO lab/windows-server-2025-arm64 1
#   PRODUCT_KEY=<key> tools/build-box.sh ~/Downloads/Windows11_*.iso lab/windows-11-arm64 3
# Optional: VIRTIO_ISO=/path/virtio-win.iso installs the NetKVM ARM64 driver (needed for Windows 11,
#   where the default NIC has no driver; then set the VM NIC type to virtio in the Vagrantfile).
# The box ships C:\lab\sysprep.ps1: run it on every cloned server before joining a domain
#   (clones share one machine SID); it must run as SYSTEM, which the helper arranges.
# Image indexes: wiminfo <mounted-iso>/sources/install.wim (brew install wimlib)
set -euo pipefail

ISO=${1:?iso path}
BOX=${2:?box name, e.g. lab/windows-11-arm64}
INDEX=${3:-1}
DISK_GB=${4:-60}
MEM=${5:-4096}
VM="build-${BOX//\//-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
VMDIR="$HOME/VirtualBox VMs/$VM"
OUT_DIR="$HERE/../boxes"
GA_ISO=/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso
mkdir -p "$OUT_DIR"

# First-logon script: Guest Additions, WinRM for Vagrant/Ansible, no password expiry.
PS_SCRIPT=$(cat <<'PS'
$ErrorActionPreference = 'Continue'
Start-Transcript C:\vagrant-setup.log
foreach ($d in (Get-PSDrive -PSProvider FileSystem)) {
  $ga = Join-Path $d.Root 'VBoxWindowsAdditions-arm64.exe'
  if (Test-Path $ga) { Start-Process $ga -ArgumentList '/S' -Wait; break }
}
foreach ($d in (Get-PSDrive -PSProvider FileSystem)) {
  $inf = Join-Path $d.Root 'NetKVM\w11\ARM64\netkvm.inf'
  if (Test-Path $inf) { pnputil /add-driver $inf /install; break }
}
Start-Sleep 10
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
Enable-PSRemoting -Force -SkipNetworkProfileCheck
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
Set-Service WinRM -StartupType Automatic
netsh advfirewall firewall add rule name=WinRM-HTTP dir=in action=allow protocol=TCP localport=5985
Set-LocalUser vagrant -PasswordNeverExpires $true
Set-LocalUser Administrator -PasswordNeverExpires $true
# Helpers for cloned VMs: SetupComplete re-applies WinRM settings after sysprep.
New-Item C:\lab, C:\Windows\Setup\Scripts -ItemType Directory -Force | Out-Null
Copy-Item "$PSScriptRoot\sysprep.ps1" C:\lab\sysprep.ps1
Copy-Item "$PSScriptRoot\SetupComplete.cmd" C:\Windows\Setup\Scripts\SetupComplete.cmd
powercfg /h off
powercfg /change standby-timeout-ac 0
New-Item C:\vagrant-ready -ItemType File -Force
Stop-Transcript
PS
)
KEY_XML="<ProductKey><Key></Key><WillShowUI>OnError</WillShowUI></ProductKey>"
[ -n "${PRODUCT_KEY:-}" ] && KEY_XML="<ProductKey><Key>$PRODUCT_KEY</Key><WillShowUI>OnError</WillShowUI></ProductKey>"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir "$WORK/answer"
printf '%s\r\n' "$PS_SCRIPT" > "$WORK/answer/vagrant-setup.ps1"
cat > "$WORK/answer/SetupComplete.cmd" <<'CMD'
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private; Set-Service WinRM -StartupType Automatic; Start-Service WinRM; winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'; winrm set winrm/config/service/auth '@{Basic=\"true\"}'; netsh advfirewall firewall add rule name=WinRM-HTTP dir=in action=allow protocol=TCP localport=5985"
CMD
cat > "$WORK/answer/sysprep.ps1" <<'SYS'
# Generalize this clone (new SID) and shut down; runs sysprep as SYSTEM via a one-shot task.
$u = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem">
<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
<OOBE><HideEULAPage>true</HideEULAPage><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><ProtectYourPC>3</ProtectYourPC><SkipMachineOOBE>true</SkipMachineOOBE><SkipUserOOBE>true</SkipUserOOBE></OOBE>
<UserAccounts><AdministratorPassword><Value>vagrant</Value><PlainText>true</PlainText></AdministratorPassword></UserAccounts>
<AutoLogon><Enabled>true</Enabled><Username>vagrant</Username><Password><Value>vagrant</Value><PlainText>true</PlainText></Password><LogonCount>999</LogonCount></AutoLogon>
</component></settings></unattend>
'@
Set-Content C:\lab\unattend.xml $u
$a = New-ScheduledTaskAction -Execute C:\Windows\System32\Sysprep\sysprep.exe -Argument '/generalize /oobe /shutdown /unattend:C:\lab\unattend.xml'
Register-ScheduledTask -TaskName LabSysprep -Action $a -User SYSTEM -RunLevel Highest -Force | Out-Null
Start-ScheduledTask -TaskName LabSysprep
SYS
sed -e "s|@INDEX@|$INDEX|" -e "s|@PRODUCTKEY@|$KEY_XML|" \
    -e "s|@COMPUTERNAME@|vagrant-win|" \
    "$HERE/Autounattend.xml.tpl" > "$WORK/answer/Autounattend.xml"
hdiutil makehybrid -quiet -iso -joliet -default-volume-name ANSWER \
  -o "$WORK/answer.iso" "$WORK/answer"

# Start clean if a previous build attempt exists.
if VBoxManage showvminfo "$VM" >/dev/null 2>&1; then
  VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
  sleep 2
  VBoxManage unregistervm "$VM" --delete
fi
rm -rf "$VMDIR"

VBoxManage createvm --name "$VM" --platform-architecture=arm \
  --ostype=Windows11_arm64 --default --register
VBoxManage modifyvm "$VM" --memory "$MEM" --cpus 2
VBoxManage createmedium disk --filename "$VMDIR/$VM.vdi" --size $((DISK_GB * 1024))
VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$VMDIR/$VM.vdi"
VBoxManage storageattach "$VM" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$ISO"
cp "$WORK/answer.iso" "$VMDIR/answer.iso"
VBoxManage storageattach "$VM" --storagectl SATA --port 2 --device 0 --type dvddrive --medium "$VMDIR/answer.iso"
VBoxManage storageattach "$VM" --storagectl SATA --port 3 --device 0 --type dvddrive --medium "$GA_ISO"
if [ -n "${VIRTIO_ISO:-}" ]; then
  VBoxManage storageattach "$VM" --storagectl SATA --port 4 --device 0 --type dvddrive --medium "$VIRTIO_ISO"
fi
VBoxManage modifyvm "$VM" --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage startvm "$VM" --type gui
# Answer the "Press any key to boot from CD or DVD" prompt.
for _ in $(seq 1 10); do sleep 1; VBoxManage controlvm "$VM" keyboardputscancode 39 b9 2>/dev/null || true; done

cat <<MSG
Install started for $VM (several reboots). When C:\\vagrant-ready exists, shut the VM down, then run:
  vagrant package --base "$VM" --output "$OUT_DIR/$(basename "$BOX").box"
  vagrant box add "$BOX" "$OUT_DIR/$(basename "$BOX").box"
MSG
