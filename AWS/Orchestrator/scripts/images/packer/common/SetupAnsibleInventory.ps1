param(
    [string]$winrm_insecure = $env:PACKER_WINRMINSEC,
    [string]$winrm_username = $env:USERNAME,
    [string]$winrm_password = $env:PACKER_PASSWORD,
    [string]$winrm_use_ssl = $env:PACKER_USESSL
)

#Convert 'packer speak' of true/false to actual values
If ([System.Convert]::ToBoolean($winrm_use_ssl)) {$winrm_port = '5986'} else {$winrm_port = '5985'}    
If ([System.Convert]::ToBoolean($winrm_insecure)) {$winrm_certval = 'ignore'} else {$winrm_certval = 'validate'}

#Grab current IP
$IPAddress = (get-WmiObject Win32_NetworkAdapterConfiguration|Where-Object {$_.Ipaddress.length -gt 1}).ipaddress[0]

$PublicIPAddress = (Invoke-WebRequest -uri "https://api.ipify.org/" -UseBasicParsing).Content

#build a template
$content = "[default]`n[[IPADDRESS]]`n`n[default:vars]`nansible_connection=winrm`nansible_port=[[PORT]]`nansible_winrm_transport=basic`nansible_user=[[USER]]`nansible_password=[[PASS]]`nansible_winrm_message_encryption=auto`nansible_winrm_server_cert_validation=[[INSEC]]`nansible_winrm_read_timeout_sec=1200`n"

#Update content with connectionstrings
$content = $content.replace('[[IPADDRESS]]',$PublicIPAddress)
$content = $content.replace('[[USER]]',$winrm_username)
$content = $content.replace('[[PASS]]',$winrm_password)
$content = $content.replace('[[PORT]]',$winrm_port)
$content = $content.replace('[[INSEC]]',$winrm_certval)

#commit the file
Set-Content -Path inventory.txt -Value $content -force
