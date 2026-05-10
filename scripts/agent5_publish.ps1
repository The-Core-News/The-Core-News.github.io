$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
$APPROVED_PATH = "$TEMP_PATH\approved"
$today = (Get-Date).ToString("yyyy-MM-dd")
$SLACK_WEBHOOK = [Environment]::GetEnvironmentVariable("SLACK_WEBHOOK", "Machine")

function Send-Slack($message) {
    $body = [System.Text.Encoding]::UTF8.GetBytes("{`"text`":`"$message`"}")
    Invoke-RestMethod -Uri $SLACK_WEBHOOK -Method Post -Body $body -ContentType "application/json; charset=utf-8"
}

function Update-Index($filename, $title, $category) {
    $indexPath = "$BLOG_PATH\index.md"
    $marker = "<!-- NEW_POST_$($category.ToUpper()) -->"
    $postName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $newLink = "- [$title]($postName.md)"

    $content = Get-Content $indexPath -Raw -Encoding UTF8

    if ($content -match [regex]::Escape($postName)) {
        Write-Host "[Agent 5] Already in index: $filename" -ForegroundColor Yellow
        return
    }

    $content = $content -replace [regex]::Escape($marker), "$marker`r`n$newLink"
    [System.IO.File]::WriteAllText($indexPath, $content, [System.Text.Encoding]::UTF8)
    Write-Host "[Agent 5] Index updated: $filename" -ForegroundColor Green
}

Write-Host "[Agent 5] Publishing..." -ForegroundColor Cyan

$approvedFiles = Get-ChildItem -Path $APPROVED_PATH -Filter "*.md"
if ($approvedFiles.Count -eq 0) {
    Write-Host "[Agent 5] No files to publish." -ForegroundColor Red
    Send-Slack "❌ [The Core News] $today - 업로드할 포스트가 없습니다."
    exit 1
}

foreach ($file in $approvedFiles) {
    # 루트에 복사 (기존 포스트와 동일한 구조)
    $dest = "$BLOG_PATH\$($file.Name)"
    if (Test-Path $dest) { $dest = "$BLOG_PATH\$($file.BaseName)-2.md" }
    Copy-Item $file.FullName -Destination $dest
    Write-Host "[Agent 5] Copied: $($file.Name)" -ForegroundColor Green

    # # 제목 형식에서 title 추출
    $title = (Get-Content $file.FullName -Encoding UTF8 | Where-Object { $_ -match "^# " } | Select-Object -First 1) -replace "^# ", ""

    # 카테고리 판단
    if ($file.Name -match "security") { $cat = "security" }
    elseif ($file.Name -match "ai")   { $cat = "ai" }
    else                               { $cat = "it" }

    if ($title) {
        Update-Index -filename $file.Name -title $title -category $cat
    } else {
        Write-Host "[Agent 5] Warning: title not found in $($file.Name)" -ForegroundColor Yellow
    }
}

Remove-Item -Path $TEMP_PATH -Recurse -Force
Write-Host "[Agent 5] Temp files cleaned." -ForegroundColor Green

Set-Location $BLOG_PATH
git add -A
git commit -m "Auto post: $today ($($approvedFiles.Count) posts)"
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "[Agent 5] Push complete!" -ForegroundColor Green
    $postList = ($approvedFiles | ForEach-Object { "• $($_.Name)" }) -join "\n"
    Send-Slack "✅ [The Core News] $today 업로드 완료!\n포스트 $($approvedFiles.Count)개\n$postList\nhttps://the-core-news.github.io"
} else {
    Write-Host "[Agent 5] Push failed." -ForegroundColor Red
    Send-Slack "⚠️ [The Core News] $today - git push 실패! 로그 확인 필요."
}
