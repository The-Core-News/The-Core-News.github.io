$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"

New-Item -ItemType Directory -Force -Path $TEMP_PATH | Out-Null

$existingPosts = Get-ChildItem -Path $BLOG_PATH -Filter "*.md" |
    Select-Object -ExpandProperty Name | Out-String

Write-Host "[Agent 1] Collecting news..." -ForegroundColor Cyan

$result = & "C:\Users\user\.local\bin\claude.exe" -p @"
You are a news collection bot. Fetch recent news from the sources below using WebFetch.

Sources:
- Security: https://cvefeed.io/rssfeed/latest.xml
- Security: https://www.cisa.gov/news-events/cybersecurity-advisories
- AI: https://hnrss.org/frontpage (AI, LLM, machine learning items only)
- IT: https://hnrss.org/frontpage (dev, trends, open source items only)

Already published posts (avoid duplicates):
$existingPosts

Output JSON only, no explanation, no markdown fences:
{
  "security": [
    {"title": "title", "url": "url", "summary": "one line summary", "severity": "HIGH/MEDIUM/LOW/NA", "date": "date"}
  ],
  "ai": [
    {"title": "title", "url": "url", "summary": "one line summary", "date": "date"}
  ],
  "it": [
    {"title": "title", "url": "url", "summary": "one line summary", "date": "date"}
  ]
}
At least 3 items per category.
"@ --allowedTools "WebFetch"

$result | Out-File -FilePath "$TEMP_PATH\candidates.json" -Encoding UTF8
Write-Host "[Agent 1] Done - candidates.json saved." -ForegroundColor Green
