
Get-ADComputer -Filter * -SearchBase "OU=Servers,DC=us,DC=cambridge" -properties *| select name, whenchanged | Export-Csv -Path "C:\Users\cooper.hoy\Desktop\Servers.csv" -NoTypeInformation
