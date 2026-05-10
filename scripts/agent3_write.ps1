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
    param($category, $categoryKR, $filePrefix, $tag)

    $briefPath = "$TEMP_PATH\brief_$category.json"
    $selectedObj.$category | ConvertTo-Json -Depth 5 | Out-File -FilePath $briefPath -Encoding UTF8

    $prompt = @"
You are a 20-year veteran tech journalist and columnist. You have covered cybersecurity, AI, and software engineering for major Korean tech publications. Practitioners trust your work because you never sensationalize and never bluff. Your analysis is grounded, your opinions are earned.

Your editorial brief is in the file at path: $briefPath
Step 1: Read it using Bash (read only — do NOT write or save any files at any point).
Step 2: Fetch the original URL from the brief with WebFetch to verify the facts.

Writing rules:

[FACTS]
- Write only what you can verify from the source or from widely corroborated reports.
- State facts directly and confidently. Cite the source inline when making specific claims.
- Do not pad with vague generalities. Every sentence must earn its place.

[SPECULATION / PREDICTION]
- Anything not yet confirmed must be clearly signaled with explicit Korean hedging phrases.
- Use phrases meaning: "expected to", "may be possible", "experts are concerned that", "not yet officially confirmed".
- Never present a projection or inference as an established fact.
- Your expert opinion is welcome but must be labeled as personal analysis, not established fact.
- Example label: phrases like "in this journalist's view after tracking similar cases for 20 years".

[STYLE]
- This is not a translation. Write as an analyst who has seen this pattern before.
- Use the editorial_angle from the brief as your framing lens.
- Cover the key_points from the brief. Distinguish confirmed_facts from speculation_flags explicitly in the text.
- Add the korean_context: make it concrete and relevant to what Korean teams face today.
- Include actionable recommendations: what should readers do right now?
- Minimum 1200 characters. Natural, authoritative Korean.

Output the markdown file content only. Start directly with the title as a level-1 heading:
# 제목을 여기에 (Korean title)

Then write the body. No front matter. No code blocks. No extra explanation.
"@

    $result = & "C:\Users\user\.local\bin\claude.exe" -p $prompt --allowedTools "Bash,WebFetch"

    # # 제목으로 시작하는 실제 마크다운만 추출
    $mdMatch = [regex]::Match($result, '(?s)(# .+)')
    if ($mdMatch.Success) { $result = $mdMatch.Value }

    $filename = "$today-$filePrefix.md"
    [System.IO.File]::WriteAllText("$DRAFTS_PATH\$filename", $result, [System.Text.Encoding]::UTF8)
    Write-Host "[Agent 3] Done: $filename" -ForegroundColor Green
}

Write-Post -category "security" -categoryKR "security" -filePrefix "security" -tag "security"
Write-Post -category "ai"       -categoryKR "ai"       -filePrefix "ai"       -tag "ai"
Write-Post -category "it"       -categoryKR "it"       -filePrefix "it"       -tag "it"

Write-Host "[Agent 3] All posts written." -ForegroundColor Green
