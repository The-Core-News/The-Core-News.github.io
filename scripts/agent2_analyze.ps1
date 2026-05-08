$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"

$candidates = Get-Content "$TEMP_PATH\candidates.json" -Encoding UTF8 -Raw

Write-Host "[Agent 2] Analyzing and selecting..." -ForegroundColor Cyan

$result = & "C:\Users\user\.local\bin\claude.exe" -p @"
You are a blog editor. Analyze the candidate news list and select the best 1 item per category.

Candidate list:
$candidates

Scoring criteria (1-10 each):
- Credibility: is the source authoritative (CISA, NVD, major tech media)?
- Impact: does it affect many people or systems?
- Reader interest: will Korean IT readers care about this?
- Freshness: recent and not yet widely covered?

Output JSON only, no explanation, no markdown fences:
{
  "security": {"title": "title", "url": "url", "summary": "summary", "reason": "why selected", "score": 0},
  "ai":       {"title": "title", "url": "url", "summary": "summary", "reason": "why selected", "score": 0},
  "it":       {"title": "title", "url": "url", "summary": "summary", "reason": "why selected", "score": 0}
}
"@ --allowedTools "WebFetch"

$result | Out-File -FilePath "$TEMP_PATH\selected.json" -Encoding UTF8
Write-Host "[Agent 2] Done - selected.json saved." -ForegroundColor Green
