$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
$APPROVED_PATH = "$TEMP_PATH\approved"
$today = (Get-Date).ToString("yyyy-MM-dd")
$SLACK_WEBHOOK = "https://hooks.slack.com/services/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"

Write-Host "[Agent 5] Publishing..." -ForegroundColor Cyan

$approvedFiles = Get-ChildItem -Path $APPROVED_PATH -Filter "*.md"

if ($approvedFiles.Count -eq 0) {
    Write-Host "[Agent 5] No files to publish." -ForegroundColor Red
    $body = '{"text":"❌ [The Core News] ' + $today + ' - 업로드할 포스트가 없습니다."}'
    Invoke-RestMethod -Uri $SLACK_WEBHOOK -Method Post -Body $body -ContentType "application/json"
    exit 1
}

foreach ($file in $approvedFiles) {
    $dest = "$BLOG_PATH\$($file.Name)"
    if (Test-Path $dest) { $dest = "$BLOG_PATH\$($file.BaseName)-2.md" }
    Copy-Item $file.FullName -Destination $dest
    Write-Host "[Agent 5] Copied: $($file.Name)" -ForegroundColor Green
}

Set-Location $BLOG_PATH
git add -A
git commit -m "Auto post: $today ($($approvedFiles.Count) posts)"
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "[Agent 5] Push complete!" -ForegroundColor Green

    # 포스트 목록 만들기
    $postList = ($approvedFiles | ForEach-Object { "• $($_.Name)" }) -join "\n"
    $body = '{"text":"✅ [The Core News] ' + $today + ' 업로드 완료!\n포스트 ' + $approvedFiles.Count + '개\n' + $postList + '\nhttps://the-core-news.github.io"}'
    Invoke-RestMethod -Uri $SLACK_WEBHOOK -Method Post -Body $body -ContentType "application/json"
} else {
    Write-Host "[Agent 5] Push failed." -ForegroundColor Red
    $body = '{"text":"⚠️ [The Core News] ' + $today + ' - git push 실패! 로그 확인 필요."}'
    Invoke-RestMethod -Uri $SLACK_WEBHOOK -Method Post -Body $body -ContentType "application/json"
}

Remove-Item -Path $TEMP_PATH -Recurse -Force
Write-Host "[Agent 5] Temp files cleaned." -ForegroundColor Green
