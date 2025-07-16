$from= Read-Host -Prompt 'Input Username to copy from  (first.last)'
$To = Read-Host -Prompt 'Input Username to copy to   (first.last)'
Get-ADUser -Identity $from -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $To