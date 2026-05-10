$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
$DRAFTS_PATH = "$TEMP_PATH\drafts"
$today = (Get-Date).ToString("yyyy-MM-dd")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
New-Item -ItemType Directory -Force -Path $DRAFTS_PATH | Out-Null

$selected = Get-Content "$TEMP_PATH\selected.json" -Encoding UTF8 -Raw
$selected = $selected -replace '(?s)```json\s*', '' -replace '```', ''

$jsonMatch = [regex]::Match($selected, '\{[\s\S]*\}')
if (-not $jsonMatch.Success) {
    Write-Host "[Agent 3] ERROR: No JSON found in selected.json" -ForegroundColor Red
    exit 1
}
$selectedObj = $jsonMatch.Value | ConvertFrom-Json

Write-Host "[Agent 3] Writing posts..." -ForegroundColor Cyan

function Write-Post {
    param($category, $filePrefix)

    $briefPath = "$TEMP_PATH\brief_$category.json"
    $selectedObj.$category | ConvertTo-Json -Depth 5 | Out-File -FilePath $briefPath -Encoding UTF8

    $prompt = @"
You are a senior technical editor at The Core News, a Korean IT publication. Your job is to write structured technical guides for Korean IT practitioners.

Your editorial brief is in the file at path: $briefPath
Step 1: Read it using Bash (read only, do NOT write any files).
Step 2: Fetch the original URL from the brief with WebFetch to gather accurate technical details.

WRITING STYLE — follow this exactly, matching the tone of the existing blog:
- Informative and neutral. Not a newspaper column. Not opinionated narration.
- Structured sections with ## headings and ### subheadings
- Bullet points and numbered lists for technical content
- Code blocks (bash, python, etc.) where directly applicable
- Formal Korean with sentence endings: ~합니다, ~있습니다, ~합니다 (not ~다 narrative style)
- Each section must be useful on its own

TITLE FORMAT — match existing blog titles exactly:
- Security/CVE: "CVE-XXXX 제품명 취약점유형 대응 가이드"
  Example: "CVE-2026-2441 크롬 브라우저 CSS 렌더링 엔진 Use-after-free 취약점 대응 가이드"
- IT: "기술명 문제유형 해결 가이드"
  Example: "Node.js EventEmitter 메모리 누수 해결 가이드"
- AI: "서비스명 핵심내용 발표" or "주제: 부제"
  Example: "가트너 2026년 전략 기술 트렌드: AI 슈퍼컴퓨팅 발표"
No dramatic dashes (—), no editorial commentary, no parenthetical notes in the title.

REQUIRED STRUCTURE (adapt section names to fit the topic naturally):
# [위 형식에 맞는 한국어 제목]

## 개요
(2-3 sentences: what happened, why it matters)

## 상세 분석
(technical breakdown with subsections and bullet points)

## 영향 범위
(who is affected, which versions/systems)

## 대응 방법
(step-by-step with numbered lists, code blocks if applicable)

## 추가 권고 사항
(best practices, monitoring tips)

---
**출처**: [source name](url)
*The Core News 분석팀 - 기술 전문 에디터*

OUTPUT: markdown only, starting with # title. No front matter. No code fences around the whole output. No preamble.
"@

    $rawResult = & "C:\Users\user\.local\bin\claude.exe" -p $prompt --allowedTools "Bash,WebFetch" --dangerouslySkipPermissions

    # 배열을 개행으로 조인하고 # 제목부터 추출
    $result = ($rawResult -join "`n")
    $mdMatch = [regex]::Match($result, '(?s)(# .+)')
    if ($mdMatch.Success) { $result = $mdMatch.Value }

    $filename = "$today-$filePrefix.md"
    [System.IO.File]::WriteAllText("$DRAFTS_PATH\$filename", $result, [System.Text.Encoding]::UTF8)
    Write-Host "[Agent 3] Done: $filename" -ForegroundColor Green
}

Write-Post -category "security" -filePrefix "security"
Write-Post -category "ai"       -filePrefix "ai"
Write-Post -category "it"       -filePrefix "it"

Write-Host "[Agent 3] All posts written." -ForegroundColor Green
