$SCRIPT_PATH = "D:\The-Core-News.github.io\scripts"
$LOG_PATH = "$SCRIPT_PATH\logs"
$today = (Get-Date).ToString("yyyy-MM-dd")
$logFile = "$LOG_PATH\$today.log"

New-Item -ItemType Directory -Force -Path $LOG_PATH | Out-Null

function Log($msg) {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $line = "[$timestamp] $msg"
    Write-Host $line
    $line | Out-File -FilePath $logFile -Append -Encoding UTF8
}

Log "===== Pipeline Start ====="

try {
    Log ">> Agent 1: Collect"
    & "$SCRIPT_PATH\agent1_collect.ps1"

    Log ">> Agent 2: Analyze"
    & "$SCRIPT_PATH\agent2_analyze.ps1"

    Log ">> Agent 3: Write"
    & "$SCRIPT_PATH\agent3_write.ps1"

    Log ">> Agent 4: Review"
    & "$SCRIPT_PATH\agent4_review.ps1"

    Log ">> Agent 5: Publish"
    & "$SCRIPT_PATH\agent5_publish.ps1"

    Log "===== Pipeline Done ====="

} catch {
    $err = $_.ToString()
    Log "===== ERROR: $err ====="
    exit 1
}
