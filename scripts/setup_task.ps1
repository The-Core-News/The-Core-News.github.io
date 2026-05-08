# =====================================================
# setup_task.ps1
# 관리자 PowerShell로 1회만 실행하세요
# =====================================================

$scriptPath = "D:\The-Core-News.github.io\scripts\run_pipeline.ps1"

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -AtLogOn

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName "CoreNewsBlogPipeline" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -RunLevel Highest `
    -Force

Write-Host "✅ 등록 완료! 다음 로그인부터 자동 실행됩니다."
Write-Host "로그 위치: D:\The-Core-News.github.io\scripts\logs\"
