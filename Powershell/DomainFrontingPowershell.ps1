#Powershell 2.0 is the target because Windows 7 and Server 2008R2 ship with this as standard, so 2.0 is the current baseline

#Unfortunatly WebClient is a bust because the host header is considered restricted
#^This restrition comes from the WebHeaderCollection class so the WebRequest classes are out as well because that's how they all implement headers.

#Powershell doesn't appear to support polymorphism so duplicated code for http and https

function httpsFront([System.Net.Sockets.NetworkStream] $networkStream, [string] $front, [string] $redirector, [string] $get){
    $sslStream = New-Object System.Net.Security.SslStream($networkStream, $false)

    $sslStream.AuthenticateAsClient($front)

    $getString = "GET " + $get + " HTTP/1.1`r`nHost: " + $redirector + "`r`nContent-Length: 0`r`nConnection: Close`r`n`r`n"
    $byteGetString = [System.Text.Encoding]::ASCII.GetBytes($getString)

    $sslStream.Write($byteGetString, 0, $byteGetString.length)

    $buffer = New-Object System.Byte[] 1024

    $rawResponse = $sslStream.Read($buffer, 0, 1024)
    $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $rawResponse)
    Write-Host $response
}

function httpFront([System.Net.Sockets.NetworkStream] $networkStream, [string] $front, [string] $redirector, [string] $get){
    $getString = "GET " + $get + " HTTP/1.1`r`nHost: " + $redirector + "`r`nContent-Length: 0`r`nConnection: Close`r`n`r`n"
    $byteGetString = [System.Text.Encoding]::ASCII.GetBytes($getString)

    $networkStream.Write($byteGetString, 0, $byteGetString.length)

    $buffer = New-Object System.Byte[] 1024

    $rawResponse = $networkStream.Read($buffer, 0, 1024)
    $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $rawResponse)
    Write-Host $response
}

function DomainFront([string] $front, [string] $redirector, [int] $port, [string] $get)
{
    #Perform a DNS lookup on the domain front
    $frontIPAddress = [System.Net.Dns]::GetHostAddresses($front)

    #Iterate over all IP Addresses returned by DNS in case the first X aren't responding.
    Foreach($IP in $frontIPAddress){
        try{
            $frontIPEndPoint = New-Object System.Net.IPEndPoint($IP, $port)
            $sock = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
            $sock.Connect($frontIPEndPoint)
            break #We have a succesful connection, don't try any more IP's returned by the DNS server
        }
        catch{
            Write-Host _$
            continue
        }
    }

    #Create the socket and connect to the domain front
    $sock = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
    $sock.Connect($frontIPEndPoint)

    #Abstract to Network Stream class to better support SSL
    $networkStream = New-Object System.Net.Sockets.NetworkStream($sock)

    if($port -eq 443){
        httpsFront $networkStream $front $redirector $get
    }
    else{
        httpFront $networkStream $front $redirector $get
    }
}