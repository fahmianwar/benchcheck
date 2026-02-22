# =========================
# BenchCheck Windows v1.0
# =========================

function Color-Print($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Host "================ BenchCheck Windows ================" -ForegroundColor Cyan
Write-Host "Generated : $(Get-Date)"
Write-Host "---------------------------------------------------"

# OS Info
$os = Get-CimInstance Win32_OperatingSystem
$hostname = $env:COMPUTERNAME
$arch = $os.OSArchitecture
$kernel = $os.Version

Write-Host "Hostname            : $hostname"
Write-Host "OS                  : $($os.Caption)"
Write-Host "Architecture        : $arch"
Write-Host "Kernel Version      : $kernel"

Write-Host "---------------------------------------------------"

# CPU Info
$cpu = Get-CimInstance Win32_Processor
Write-Host "CPU Model           : $($cpu.Name)"
Write-Host "CPU Cores           : $($cpu.NumberOfCores)"
Write-Host "Logical Processors  : $($cpu.NumberOfLogicalProcessors)"

# RAM Info
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1024)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1024)
$usedRAM = $totalRAM - $freeRAM
$ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100)

if ($ramPercent -gt 80) {
    Color-Print "RAM Usage           : $usedRAM MB / $totalRAM MB ($ramPercent%)" Red
}
elseif ($ramPercent -gt 60) {
    Color-Print "RAM Usage           : $usedRAM MB / $totalRAM MB ($ramPercent%)" Yellow
}
else {
    Color-Print "RAM Usage           : $usedRAM MB / $totalRAM MB ($ramPercent%)" Green
}

# Disk Info
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $used = $_.Used / 1GB
    $free = $_.Free / 1GB
    $total = $used + $free
    $percent = [math]::Round(($used / $total) * 100)

    if ($percent -gt 80) {
        Color-Print "Disk $($_.Name): $([math]::Round($used,2))GB / $([math]::Round($total,2))GB ($percent%)" Red
    }
    elseif ($percent -gt 60) {
        Color-Print "Disk $($_.Name): $([math]::Round($used,2))GB / $([math]::Round($total,2))GB ($percent%)" Yellow
    }
    else {
        Color-Print "Disk $($_.Name): $([math]::Round($used,2))GB / $([math]::Round($total,2))GB ($percent%)" Green
    }
}

Write-Host "---------------------------------------------------"

# Network Info
$ipv4 = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
        Where-Object {$_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*"} | 
        Select-Object -First 1 -ExpandProperty IPAddress

$ipv6 = Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue | 
        Where-Object {$_.IPAddress -notlike "fe80*"} | 
        Select-Object -First 1 -ExpandProperty IPAddress

if ($ipv4) {
    Color-Print "IPv4 Address        : $ipv4" Green
} else {
    Color-Print "IPv4 Address        : Not detected" Red
}

if ($ipv6) {
    Color-Print "IPv6 Address        : $ipv6" Green
} else {
    Color-Print "IPv6 Address        : Not detected" Red
}

Write-Host "---------------------------------------------------"

# Uptime
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "System Uptime       : $($uptime.Days) Days $($uptime.Hours) Hours"

# Health Score
$score = 100
if ($ramPercent -gt 80) { $score -= 20 }
if ($ramPercent -gt 60) { $score -= 10 }

Write-Host "---------------------------------------------------"
if ($score -ge 80) {
    Color-Print "Health Score        : $score / 100" Green
}
elseif ($score -ge 60) {
    Color-Print "Health Score        : $score / 100" Yellow
}
else {
    Color-Print "Health Score        : $score / 100" Red
}

Write-Host "===================================================" -ForegroundColor Cyan
