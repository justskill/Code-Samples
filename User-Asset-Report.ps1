<#======================================

Script Name: User-Asset-Report.ps1
Written By: Mitchell Skillman
Script Version: 1.1
PowerShell Version: ---

======================================#>

<#======================================

.SYNOPSIS
    Checks a shared mailbox for a report of terminated users and cross references those against the
    asset database to determine what assets need to be retreived.
.DESCRIPTION
    The script file can be executed manually or via a scheduled task.  There are no parameters or inputs required
    as states are determined by the mail server.
.PARAMETER
    N/A
.EXAMPLE
    .\User-Asset-Report.ps1

======================================#>

# Secure credentials salted and encrypted into a text document (for unattended access).  This is for DesktopAppUser.
$password = Get-Content "**************" | Convertto-Securestring
$cred     = New-Object -typename System.Management.Automation.PSCredential -argumentlist "******************",$password

# Hash in case of multiple files.
$files = @()

# Outlook API basics
$sharedMailbox = "*********************"
$url           = "https://outlook.office365.com/api/v1.0/users/$sharedMailbox/messages"
$date          = Get-Date -format FileDate

# We may need to check if there are multiple messages received 
$messageQuery = $url + "?`$select=Id"
$messages     = Invoke-RestMethod $messageQuery -Credential $cred

# Loop through each results
foreach ($message in $messages.value) {

    # get attachments and save to file system
    $query = $url + "/" + $message.Id + "/attachments"
    $attachments = Invoke-RestMethod $query -Credential $cred

    # In case of multiple attachments in email
    foreach ($attachment in $attachments.value) {
        if ($attachment.Name -like "*.jpg"){ continue }
        $path = "*********" + $date + "." + $attachment.Name
        $files += $path
        
        # Convert the attachment to something machine-readable 
        $Content = [System.Convert]::FromBase64String($attachment.ContentBytes)
        Set-Content -Path $path -Value $Content -Encoding Byte
    }

    # Basics of multiple attachment handling.  For now, we're gonna throw an error.
    if ($files.count -gt 1) {
        Invoke-RestMethod -method POST -body "********************" -URI "***************************"
        throw "Multiple files found"
    }

    # Move processed email to a subfolder on O365
    $query = $url + "/" + $message.Id + "/move"
    $body  = "{""DestinationId"":""******************************************************************""}"
    Invoke-RestMethod $query -Body $body -ContentType "application/json" -Method post -Credential $cred
}

# We will want to keep track of various things when this script runs.
$LogPath = "$Env:USERPROFILE\Logs\SlackBot.log"

# Instantiating and clearing our re-used variables.
$row = New-Object PsObject
$assetHash = @()

# This is where we gather our list of user id's.  
$users = Import-Csv $path

foreach ($user in $users."Employee ID") {
    $query = Invoke-RestMethod "*****************************************************"

    if ($query.Content -eq "[]`n") {
        # User not found
        Write-verbose "No assets found for $user"
        continue
    }

    # Get the user details from the asset (Otherwise we would only have their id)
    $assetUser  = Invoke-RestMethod "*****************************************************************"
    $assetUser  = ConvertFrom-Json $assetUser.Content
    $clientName = $assetUser.lastName + ", " + $assetUser.firstName + "($user)"

    # Gather the assets assigned to the user.
    $assets = (convertfrom-json $query.Content)
    
    # Iterate through the assets and add the details to our hash for exporting.
    foreach ($asset in $assets.assetNumber) {
        # Get the asset details
        $query    = Invoke-RestMethod "************************************************************************"
        $psobject = ConvertFrom-Json $query

        # Duplicate asset detections
        if ($psobject.count -gt 1) {
            write-verbose "Duplicate asset #$asset"
            $psobject = $psobject[0]
        }

        # Populate desired fields into variables
        $model    = $psobject.model.modelname
        $Serial   = $psobject.serialNumber
        $status   = $psobject.assetstatus.id
        $location = $psobject.location.locationName
        $type     = $psobject.model.assettype.assetType

        switch($status) {
            1 { $status = "Deployed" }
            2 { $status = "Disposed" }
            3 { $status = "Needs Repair" }
            4 { $status = "Stock" }
        }

        # Populate the CSV row with our gathered information
        $row = @{
            Name      = $clientName
            Status    = $status
            Assetnum  = $asset
            Model     = $model
            Serial    = $Serial
            Location  = $location
            AssetType = $type
        }

    # Append the generated row to the main hash.
    $assetHash += New-Object PSObject -Property $row
    }
}

# Final export of our information
$assetHash | export-csv -NoTypeInformation -path ("*************" + "TermAssetReport_" + $date + ".csv")