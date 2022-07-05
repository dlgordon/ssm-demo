$InstanceId = $(Get-EC2InstanceMetadata -Category InstanceId)
$HostName = (gi Env:\COMPUTERNAME).Value
$AdminUser = "adm_$HostName"
$PasswordString = $(-join ((33..90) + (97..122) | Get-Random -Count 24| % {[char]$_}))
$AdminPassword = ConvertTo-SecureString -String $PasswordString -AsPlainText -Force
Write-SSMParameter -Name "/windows/local/$InstanceId/$AdminUser" -Type "SecureString" -Force -Overwrite $true -Value $PasswordString
$localUser = Get-LocalUser $AdminUser -ErrorAction Continue
if ($localUser -eq $null) {
    $localUser = New-LocalUser $AdminUser -Password $AdminPassword -FullName "Local Admin"
    Add-LocalGroupMember -Group "Administrators" -Member $localUser
} else {
    $localUser | Set-LocalUser -Password $AdminPassword
}
