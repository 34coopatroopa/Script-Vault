$from= Read-Host -Prompt 'Input Username to copy From'
$To = Read-Host -Prompt 'Input Username to copy to'
Get-ADUser -Identity $from -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $To
