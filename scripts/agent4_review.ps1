$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
$DRAFTS_PATH = "$TEMP_PATH\drafts"
$APPROVED_PATH = "$TEMP_PATH\approved"
New-Item -ItemType Directory -Force -Path $APPROVED_PATH | Out-Null

Write-Host "[Agent 4] Validating posts..." -ForegroundColor Cyan

$drafts = Get-ChildItem -Path $DRAFTS_PATH -Filter "*.md"

foreach ($draft in $drafts) {
    $content = Get-Content $draft.FullName -Raw -Encoding UTF8
    $issues = @()

    if ($content -notmatch '(?s)^---.*?layout:.*?title:.*?date:.*?categories:.*?tags:.*?excerpt:.*?---') {
        $issues += "front matter incomplete"
    }

    if ($content.Length -lt 1200) {
        $issues += "too short ($($content.Length) chars)"
    }

    if ($issues.Count -eq 0) {
        Write-Host "[Agent 4] PASS: $($draft.Name)" -ForegroundColor Green
    } else {
        Write-Host "[Agent 4] WARN: $($draft.Name) — $($issues -join ', ')" -ForegroundColor Yellow
    }

    Copy-Item $draft.FullName -Destination "$APPROVED_PATH\$($draft.Name)" -Force
}

$approvedCount = (Get-ChildItem -Path $APPROVED_PATH -Filter "*.md").Count
Write-Host "[Agent 4] Done - $approvedCount approved." -ForegroundColor Green
