# game_monitor.ps1 - 게임 프로세스 감지 후 슬랙 알림

$SLACK_WEBHOOK = [Environment]::GetEnvironmentVariable("SLACK_WEBHOOK", "Machine")

function Send-Slack($message) {
    $body = [System.Text.Encoding]::UTF8.GetBytes("{`"text`":`"$message`"}")
    Invoke-RestMethod -Uri $SLACK_WEBHOOK -Method Post -Body $body -ContentType "application/json; charset=utf-8"
}

# 감지할 게임 목록 (프로세스명: 표시이름)
$games = @{
    "RobloxPlayerBeta" = "🎮 로블록스"
    "Minecraft"        = "⛏️ 마인크래프트"
    "javaw"            = "⛏️ 마인크래프트 (Java)"
    "steam"            = "🕹️ Steam"
    "EpicGamesLauncher"= "🕹️ 에픽게임즈"
    "LeagueClient"     = "⚔️ 리그오브레전드"
    "FortniteClient"   = "🔫 포트나이트"
}

$alerted = @{}  # 이미 알림 보낸 게임 추적

Write-Host "[GameMonitor] Started. Watching for games..." -ForegroundColor Cyan

while ($true) {
    $now = (Get-Date).ToString("HH:mm")
    $today = (Get-Date).ToString("yyyy-MM-dd")

    foreach ($proc in $games.Keys) {
        $running = Get-Process -Name $proc -ErrorAction SilentlyContinue

        if ($running -and -not $alerted[$proc]) {
            # 게임 시작 감지
            $gameName = $games[$proc]
            Write-Host "[$now] Detected: $gameName" -ForegroundColor Yellow
            Send-Slack "👧 [$today $now] 딸이 $gameName 을 시작했어요!"
            $alerted[$proc] = $true
        }
        elseif (-not $running -and $alerted[$proc]) {
            # 게임 종료 감지
            $gameName = $games[$proc]
            Write-Host "[$now] Closed: $gameName" -ForegroundColor Gray
            Send-Slack "✅ [$today $now] $gameName 종료됐어요."
            $alerted[$proc] = $false
        }
    }

    Start-Sleep -Seconds 30  # 30초마다 체크
}
