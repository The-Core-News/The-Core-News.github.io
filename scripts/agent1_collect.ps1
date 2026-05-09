$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
New-Item -ItemType Directory -Force -Path $TEMP_PATH | Out-Null

$existingPosts = Get-ChildItem -Path "$BLOG_PATH\_posts" -Filter "*.md" |
    Select-Object -ExpandProperty Name | Out-String

Write-Host "[Agent 1] Collecting and scoring news..." -ForegroundColor Cyan

$result = & "C:\Users\user\.local\bin\claude.exe" -p @"
You are a 20-year veteran cyber threat intelligence analyst, formerly a senior analyst at CISA and NSA. You have spent two decades tracking vulnerabilities, emerging threats, and technology shifts. You know exactly what is signal and what is noise.

Your task: fetch recent news from the sources below, score every item you find, and output the single highest-scoring item per category.

Sources:
- Security: https://cvefeed.io/rssfeed/latest.xml
- Security: https://www.cisa.gov/news-events/cybersecurity-advisories
- AI: https://hnrss.org/frontpage (AI, LLM, machine learning items only)
- IT: https://hnrss.org/frontpage (dev, tools, open source, engineering trends only)

Already published — skip these:
$existingPosts

Scoring criteria (each 1-10):
- impact: scale of affected systems/users, active exploitation in the wild scores higher
- credibility: source authority (CISA/NVD = 10, official vendor advisory = 8, reputable media = 6, unknown blog = 2)
- freshness: breaking today = 10, this week = 6, older = 2
- korean_relevance: how much do Korean enterprise teams or developers need to act on this?

Score every candidate. Select the top 1 per category by total score. In the analyst_note, explain in one sentence why this item beat the others.

Output JSON only. No explanation. No markdown fences. Raw JSON starting with {:
{
  "security": {
    "title": "title here",
    "url": "url here",
    "summary": "one line summary",
    "severity": "HIGH/MEDIUM/LOW",
    "date": "date here",
    "scores": {"impact": 0, "credibility": 0, "freshness": 0, "korean_relevance": 0},
    "total_score": 0,
    "analyst_note": "why this item was selected over others"
  },
  "ai": {
    "title": "title here",
    "url": "url here",
    "summary": "one line summary",
    "date": "date here",
    "scores": {"impact": 0, "credibility": 0, "freshness": 0, "korean_relevance": 0},
    "total_score": 0,
    "analyst_note": "why this item was selected over others"
  },
  "it": {
    "title": "title here",
    "url": "url here",
    "summary": "one line summary",
    "date": "date here",
    "scores": {"impact": 0, "credibility": 0, "freshness": 0, "korean_relevance": 0},
    "total_score": 0,
    "analyst_note": "why this item was selected over others"
  }
}
"@ --allowedTools "WebFetch"

$result | Out-File -FilePath "$TEMP_PATH\candidates.json" -Encoding UTF8
Write-Host "[Agent 1] Done - top candidates saved." -ForegroundColor Green
