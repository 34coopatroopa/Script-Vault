
Get-ADComputer -Filter * -SearchBase "OU=,DC=,DC=" -properties *| select name, whenchanged | Export-Csv -Path "C:\" -NoTypeInformation
