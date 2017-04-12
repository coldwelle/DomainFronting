function DomainFront([string] $front, [string] $redirector, [int] $port)
{
    $frontIPAddress = [System.Net.Dns]::GetHostAddresses($front)
    $frontIPAddress = [System.Net.IPAddress]::Parse($frontIPAddress)#Need to figure out why this is neccessary as the above is the same type with same value. Possibly a space being appended to "IPAddressToString" field?
    $frontIPEndPoint = [System.Net.IPEndPoint]::new($frontIPAddress, $port)
    
    $sock = [System.Net.Sockets.Socket]::new([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
    $sock.Connect($frontIPEndPoint)

    #Powershell, as I have just discovered uses `n instead of \n
    $getString = "GET /one/one.txt HTTP/1.1`r`nHost: " + $redirector + "`r`nContent-Length: 0`r`nConnection: Close`r`n`r`n"
    $byteGetString = [System.Text.Encoding]::ASCII.GetBytes($getString)
    
    $byteReceive = New-Object System.Byte[] 1024

    $sock.Send($byteGetString, $byteGetString.Length, 0)

    $byte = $sock.Receive($byteReceive, $byteReceive.Length, 0)
    $strPage = [System.Text.Encoding]::ASCII.GetString($byteReceive, 0, $byte)

    while($byte -gt 0){
        $byte = $sock.Receive($byteReceive, $byteReceive.Length, 0)
        $strPage = $strPage + [System.Text.Encoding]::ASCII.GetString($byteReceive, 0, $byte)
    }
}