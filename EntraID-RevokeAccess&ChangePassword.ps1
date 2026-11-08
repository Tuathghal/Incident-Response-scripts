# Requires UPNs and new passwords, comma-delimited. Example:
# user1@domain.com,NewPwd1
# user2@domain.com,NewPwd2

# Flags to control script operations
$RevokeSessions = $true
$DisableAccount = $true
$ChangePassword = $true
$DisableDevices = $true

# Requires connection to GraphAPI
Connect-MgGaph -Scopes Directory.AccessAsUser.All

# Read in UPNs and pwds from supplied file
$filePath = Read-Host "Enter path to comma-delimited file with user principal names (UPNs) and new passwords"
$usersList = Import-Csv -Path $filePath -Header "UPN", "NewPassword"

foreach ($UserEntry in $usersList) {
    $Account = $UserEntry.UPN
    $NewPassword = $UserEntry.NewPassword

    #User information from UPN
    $User = (Get-MgUser -UserId $Account -ErrorAction SilentlyContinue)
    If (!($User)) {
        Write-Host ("Can't find an EntraID user account for {0}" -f  $Account)
        continue
    }

    Write-Host ("Revoking access and changing password for account {0}" -f $User.DisplayName)

    # Disable account
    If ($DisableAccount) {
        Write-Host ("Disabling account for user {0}" -f $User.DisplayName)
        Update-MgUser -UserId $User.Id -AccountEnabled:$False
    }

    # Change Password
    If ($ChangePassword) {
        Write-Host ("Changing password for user {0}" -f $User.DisplayName)
        $PasswordProfile = @{
            Password = $NewPassword
            ForceChangePasswordNextSignIn = $True
        }
        Update-MgUser -UserId $User.Id -PasswordProfile $PasswordProfile
    }
    
    # Revoke authenticated sessions
    If ($RevokeSessions) {
        $RevokeStatus = Revoke-MgUserSignInSession -UserId $User.Id
        If ($RevokeStatus.value -eq $true) {
            Write-Host ("Access revoked for user {0}" -f $User.DisplayName)
        }
    }

    # Disable registered devices
    If ($DisableDevices) {
        Write-Host ("Disabling devices for user {0}" -f $User.DisplayName)
        [array]$UserDevices = GetMgUserRegisteredDevice -User $User.Id
        If ($UserDevices) {
            ForEach ($Device in $UserDevices) {
                Update-MgDevice -DeviceId $Device.Id -AccountEnabled:$False
            }
        }
    }
}

Write-Host "Operations complete for all users"