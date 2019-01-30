#Load AD Data
##Any reason not to use Get-ADObject and grab everything? Time? Perhaps a way to iterate them instead of storing as an object as there could be memory issues in a larger domain.
$UserData = Get-ADUser -filter * -Properties * #reduce to utilized values 
$GroupData = Get-ADGroup -filter * -Properties * #reduce to utilized values 
$GroupData = Get-ADGroup -filter * -Properties * #reduce to utilized values 
$ComputerData = Get-ADComputer -filter * -Properties * #reduce to utilized values

#Connect-SQLServer
##New-SQLCmd Upload $Data to $Place (add col, etc.)

#New-ScheduledTask -Date Tomorrow -Task $TheAboveScript
