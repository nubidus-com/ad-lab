# Host-only adapter = the one that is not the NAT adapter (10.0.2.x)
$natIf = (Get-NetIPAddress -AddressFamily IPv4 -IPAddress "10.0.2.*" -ErrorAction SilentlyContinue).InterfaceIndex
$ifAlias = (Get-NetAdapter -Physical | Where-Object { $_.InterfaceIndex -ne $natIf } | Select-Object -First 1).Name

# Execute privileged
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Clear old IPv4 addresses on host-only adapter
$oldIPs = Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($oldIPs) {
    $oldIPs | Remove-NetIPAddress -Confirm:$false
}

# Apply new IP configuration
New-NetIPAddress `
    -InterfaceAlias $ifAlias `
    -IPAddress "192.168.56.10" `
    -PrefixLength 24

# Set DNS servers (change/add as needed)
Set-DnsClientServerAddress `
    -InterfaceAlias $ifAlias `
    -ServerAddresses @("192.168.56.1","1.1.1.1")
