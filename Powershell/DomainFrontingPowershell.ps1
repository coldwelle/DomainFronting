#Powershell 2.0 is the target because Windows 7 and Server 2008R2 ship with this as standard, so 2.0 is the current baseline

#Unfortunatly WebClient is a bust because the host header is considered restricted
#^This restrition comes from the WebHeaderCollection class so the WebRequest classes are out as well because that's how they all implement headers.

Set-StrictMode -Version 2.0

function DomainFront([string] $front, [string] $redirector, [int] $port, [string] $get)
{
    $frontIPAddress = [System.Net.Dns]::GetHostAddresses($front)

    #If multiple ip addresses come back from the DNS lookup, frontIPAddress becomes an array of those IP Address
    #Need to figure out why this is neccessary as the above is the same type with same value. Possibly a space being appended to "IPAddressToString" field?
    $frontIPAddress = [System.Net.IPAddress]::Parse($frontIPAddress[0])
    $frontIPEndPoint = [System.Net.IPEndPoint]::new($frontIPAddress, $port)
    
    $sock = [System.Net.Sockets.Socket]::new([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
    $sock.Connect($frontIPEndPoint)

    #Powershell, as I have just discovered uses `n instead of \n
    $getString = "GET " + $get + " HTTP/1.1`r`nHost: " + $redirector + "`r`nContent-Length: 0`r`nConnection: Close`r`n`r`n"
    $byteGetString = [System.Text.Encoding]::ASCII.GetBytes($getString)
    
    $byteReceive = New-Object System.Byte[] 1024

    $sock.Send($byteGetString, $byteGetString.Length, 0)

    $byte = $sock.Receive($byteReceive, $byteReceive.Length, 0)
    $strPage = [System.Text.Encoding]::ASCII.GetString($byteReceive, 0, $byte)

    while($byte -gt 0){
        $byte = $sock.Receive($byteReceive, $byteReceive.Length, 0)
        $strPage = $strPage + [System.Text.Encoding]::ASCII.GetString($byteReceive, 0, $byte)
    }
    
    Write-Host $strPage
}