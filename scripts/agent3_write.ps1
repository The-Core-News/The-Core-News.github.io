$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
$DRAFTS_PATH = "$TEMP_PATH\drafts"
$today = (Get-Date).ToString("yyyy-MM-dd")
$todayFull = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
New-Item -ItemType Directory -Force -Path $DRAFTS_PATH | Out-Null

$selected = Get-Content "$TEMP_PATH\selected.json" -Encoding UTF8 -Raw

# ✅ 카테고리별로 항목만 파싱해서 넘기기
$selectedObj = $selected | ConvertFrom-Json

Write-Host "[Agent 3] Writing posts..." -ForegroundColor Cyan

function Write-Post {
    param($category, $categoryKR, $filePrefix, $tag)

    # ✅ 해당 카테고리 항목만 JSON으로 변환
    $item = $selectedObj.$category | ConvertTo-Json -Depth 5

    $result = & "C:\Users\user\.local\bin\claude.exe" -p @"
You are a senior editor of The Core News blog.
Write a Korean blog post about the topic below.

Topic data (JSON):
$item

Fetch the original URL with WebFetch to verify facts before writing.

Writing rules:
- Facts only. Unverified info must be marked as reported/alleged
- Not a simple translation. Write as a review with perspective and commentary
- Include actionable recommendations for readers
- Minimum 1000 characters, natural Korean language
- Include viewpoints like: this is how industry sees it, here is another angle

Output the markdown file content only. Start with this exact front matter format:
---
layout: post
title: "제목을 여기에"
date: $todayFull
categories: [$categoryKR]
tags: [$tag]
excerpt: "한 줄 요약을 여기에"
---

Output the markdown content only. No extra explanation. Do not wrap in code blocks.
"@ --allowedTools "WebFetch"

    $filename = "$today-$filePrefix.md"
    $result | Out-File -FilePath "$DRAFTS_PATH\$filename" -Encoding UTF8
    Write-Host "[Agent 3] Done: $filename" -ForegroundColor Green
}

Write-Post -category "security" -categoryKR "보안 및 취약점"          -filePrefix "security" -tag "security"
Write-Post -category "ai"       -categoryKR "최신 AI 기술 동향"        -filePrefix "ai"       -tag "ai"
Write-Post -category "it"       -categoryKR "글로벌 IT 트렌드 및 개발"  -filePrefix "it"       -tag "it"

Write-Host "[Agent 3] All posts written." -ForegroundColor Green