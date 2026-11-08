# SearchBase setting
$OU = "CN=Users,DC=domain,DC=local"

# Variables defining
$dateTimeFormat = Get-Date "yyyy-MM-dd_HHmmss"
$logFile = "C:\IncidentResponse\ADUsers-forPasswordGeneration_$dateTimeFormat.csv"
$outputFile = "C:\IncidentResponse\LOGFILE-ADUsers-PasswordGeneration_$dateTimeFormat.txt"

# Create Directory
[System.IO.Directory]::CreateDirectory('C:\IncidentResponse\')

# Initialise log array
$auditLog = @()

# AD module importation (Requires Remote Server Administration Tools (RSAT))
Import-Module ActiveDirectory

# Generate Passwords
function Generate-Password {
    $fullWords = @('Hedgehog', 'Plumber', 'Electrician', 'Magic', 'Robot', 'Time', 'Journey', 'Periphery', 'Jeopardy')

    $wordParts = ""
    1..3 | ForEach-Object { $wordParts += $fullWords | GetRandom }
    $numberPart = Get-Random -Minimum 120 -Maximum 960
    return "$wordParts$numberPart"
}

# Retrieve AD users from $OU specified earlier
try {
    $users = Get-ADUser -Filter * -SearchBase $OU -Properties sAMAccountName, Name
    $logEntry = "Successfully retrieved users from OU $OU"
    $auditLog += $logEntry
    Write-Host $logEntry
    exit
}

try {
    $users |
        Select-Object sAMAccountName, Name, Enabled |
        ForEach-Object {
            try {
                # Add NewPassword property to each retrieved user account
                $_ | Add-Member -MemberType NoteProperty -Name 'NewPassword' -Value (Generate-Password)

                $logEntry = "Password generated for $($_.sAMAccountName)"
                $auditLog += $logEntry
                Write-Host $logEntry
            }
            $_
        } |
        Export-Csv -Path $outputFile -NoTypeInformation
    
    $logEntry = "Completed Export successfully. File located at $outputFile"
    $auditLog += $logEntry
    Write-Host $logEntry
} catch {
    $logEntry = "User data exportation to CSV failed. Error: $_"
    $auditLog += $logEntry
    Write-Host $logEntry
}

# Output auditLog out to file
$auditLog | Out-File -FilePath $outputFile

Write-Host "Audit log output to $outputFile"