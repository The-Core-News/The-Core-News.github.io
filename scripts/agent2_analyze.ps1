$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"

Write-Host "[Agent 2] Building editorial brief..." -ForegroundColor Cyan

$candidatesPath = "$TEMP_PATH\candidates.json"

$result = & "C:\Users\user\.local\bin\claude.exe" -p @"
You are a 20-year veteran tech media chief editor who has led editorial teams at major Korean IT publications. You know Korean enterprise developers and security engineers deeply — what they fear, what they need to act on, and what they will ignore.

The intelligence analyst has already selected the top story per category. Your job:
1. Validate each selection. If you strongly disagree, replace it and explain why.
2. Define the editorial angle — the specific lens the journalist should use.
3. Identify the 3 most important points Korean readers must understand.
4. Separate confirmed facts from speculation so the journalist does not blur the line.
5. Add Korean context — why does this matter specifically to Korean teams right now?

Read the analyst's selections from the file at path: $candidatesPath

CRITICAL: Your very first output character must be {. No preamble. No "here is". No "now composing". No markdown fences. If any text appears before {, the pipeline crashes. Raw JSON only:
{
  "security": {
    "title": "title here",
    "url": "url here",
    "summary": "summary here",
    "editorial_angle": "the specific angle and framing the journalist should take",
    "key_points": ["most important point", "second point", "third point"],
    "confirmed_facts": ["verified fact 1", "verified fact 2"],
    "speculation_flags": ["this part is unverified or projected", "another uncertain claim"],
    "korean_context": "why Korean enterprise/developer readers must care about this right now"
  },
  "ai": {
    "title": "title here",
    "url": "url here",
    "summary": "summary here",
    "editorial_angle": "the specific angle and framing the journalist should take",
    "key_points": ["most important point", "second point", "third point"],
    "confirmed_facts": ["verified fact 1", "verified fact 2"],
    "speculation_flags": ["this part is unverified or projected", "another uncertain claim"],
    "korean_context": "why Korean enterprise/developer readers must care about this right now"
  },
  "it": {
    "title": "title here",
    "url": "url here",
    "summary": "summary here",
    "editorial_angle": "the specific angle and framing the journalist should take",
    "key_points": ["most important point", "second point", "third point"],
    "confirmed_facts": ["verified fact 1", "verified fact 2"],
    "speculation_flags": ["this part is unverified or projected", "another uncertain claim"],
    "korean_context": "why Korean enterprise/developer readers must care about this right now"
  }
}
"@ --allowedTools "Bash"

$result | Out-File -FilePath "$TEMP_PATH\selected.json" -Encoding UTF8
Write-Host "[Agent 2] Done - editorial brief saved." -ForegroundColor Green
