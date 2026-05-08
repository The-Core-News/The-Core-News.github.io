$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
$DRAFTS_PATH = "$TEMP_PATH\drafts"
$today = (Get-Date).ToString("yyyy-MM-dd")

New-Item -ItemType Directory -Force -Path $DRAFTS_PATH | Out-Null

$selected = Get-Content "$TEMP_PATH\selected.json" -Encoding UTF8 -Raw

Write-Host "[Agent 3] Writing posts..." -ForegroundColor Cyan

function Write-Post {
    param($category, $categoryKR, $filePrefix)

    $result = & "C:\Users\user\.local\bin\claude.exe" -p @"
You are a senior editor of The Core News blog.
Write a Korean blog post about the topic below.

Selected topic data (JSON):
$selected

Use the '$category' item from the JSON above.
Fetch the original URL with WebFetch to verify facts before writing.

Writing rules:
- Facts only. Unverified info must be marked as reported/alleged
- Not a simple translation. Write as a review with perspective and commentary
- Include actionable recommendations for readers
- Minimum 1000 characters, natural Korean language
- Include viewpoints like: this is how industry sees it, here is another angle

File format - start with this front matter:
---
layout: post
title: "title here"
date: $today
categories: [$categoryKR]
---

Output the markdown content only. No extra explanation or code blocks.
"@ --allowedTools "WebFetch"

    $filename = "$today-$filePrefix.md"
    $result | Out-File -FilePath "$DRAFTS_PATH\$filename" -Encoding UTF8
    Write-Host "[Agent 3] Done: $filename" -ForegroundColor Green
}

Write-Post -category "security" -categoryKR "보안 및 취약점"         -filePrefix "security"
Write-Post -category "ai"       -categoryKR "최신 AI 기술 동향"       -filePrefix "ai"
Write-Post -category "it"       -categoryKR "글로벌 IT 트렌드 및 개발" -filePrefix "it"

Write-Host "[Agent 3] All posts written." -ForegroundColor Green
