#Requires -Version 5.1
#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Copy Active Directory Group Membership Between Users
    
.DESCRIPTION
    Copies all group memberships from a source user to a destination user
    Useful for creating user accounts with identical permissions
    
.PARAMETER SourceUser
    Source username to copy group memberships from
    
.PARAMETER DestinationUser
    Destination username to copy group memberships to
    
.PARAMETER WhatIf
    Show what would be done without making changes
    
.EXAMPLE
    .\copy_ad_group_membership.ps1 -SourceUser "jdoe" -DestinationUser "jsmith"
    
.EXAMPLE
    .\copy_ad_group_membership.ps1 -SourceUser "jdoe" -DestinationUser "jsmith" -WhatIf
#> 

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceUser,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationUser,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Copy AD Group Membership Tool ===" -ForegroundColor Yellow

try {
    # Verify source user exists
    Write-Host "`nVerifying source user: $SourceUser" -ForegroundColor Cyan
    $source = Get-ADUser -Identity $SourceUser -Properties MemberOf -ErrorAction Stop
    Write-Host "Source user found" -ForegroundColor Green
    
    # Verify destination user exists
    Write-Host "Verifying destination user: $DestinationUser" -ForegroundColor Cyan
    $destination = Get-ADUser -Identity $DestinationUser -Properties MemberOf -ErrorAction Stop
    Write-Host "Destination user found" -ForegroundColor Green
    
    # Get group memberships
    $groups = $source.MemberOf
    
    if ($groups.Count -eq 0) {
        Write-Warning "Source user has no group memberships to copy"
        exit 0
    }
    
    Write-Host "`nFound $($groups.Count) group memberships to copy" -ForegroundColor Cyan
    
    # Show what will be added
    Write-Host "`nGroups to add:" -ForegroundColor Yellow
    foreach ($group in $groups) {
        $groupName = (Get-ADGroup -Identity $group).Name
        Write-Host "  - $groupName" -ForegroundColor Gray
    }
    
    # Copy memberships
    if ($PSCmdlet.ShouldProcess($DestinationUser, "Add to $($groups.Count) groups")) {
        Add-ADGroupMember -Members $DestinationUser -Identity $groups -ErrorAction Stop
        Write-Host "`nSuccessfully copied group memberships!" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Failed to copy group memberships: $_"
    exit 1
}

exit 0
