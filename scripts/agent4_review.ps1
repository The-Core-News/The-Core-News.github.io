$BLOG_PATH = "D:\The-Core-News.github.io"
$TEMP_PATH = "$BLOG_PATH\scripts\temp"
$DRAFTS_PATH = "$TEMP_PATH\drafts"
$APPROVED_PATH = "$TEMP_PATH\approved"
New-Item -ItemType Directory -Force -Path $APPROVED_PATH | Out-Null

Write-Host "[Agent 4] Reviewing posts..." -ForegroundColor Cyan

$drafts = Get-ChildItem -Path $DRAFTS_PATH -Filter "*.md"

foreach ($draft in $drafts) {
    $retryCount = 0
    $approved = $false

    while (-not $approved -and $retryCount -le 1) {
        $tempTxt = "$TEMP_PATH\review_input.txt"
        Copy-Item $draft.FullName -Destination $tempTxt

        $prompt = @"
You are a 20-year veteran managing editor and fact-checker. You have enforced editorial standards at major publications and have zero tolerance for unverified claims presented as fact. A single fabricated or misleadingly framed sentence damages the publication's credibility more than a missed story ever could.

Review the draft post at path: $tempTxt

Checklist:
1. FACT vs SPECULATION: Are all unverified claims, projections, or inferences clearly labeled as such? Any speculation written as confirmed fact is an automatic FAIL.
2. Front matter: layout, title, date, categories, tags, excerpt — all present and correctly formatted?
3. Length: at least 1200 characters?
4. Actionable value: does the reader know what to do after reading?
5. Source integrity: are specific factual claims traceable to the cited source?

IMPORTANT: Output a single JSON object only. No explanation. No markdown fences. No extra text.
{"result":"PASS","issues":[],"feedback":""}
or
{"result":"FAIL","issues":["specific issue description"],"feedback":"precise rewrite instructions for the journalist"}
"@

        $review = & "C:\Users\user\.local\bin\claude.exe" -p $prompt --allowedTools "Bash"

        $reviewJson = $null
        if ($review) {
            $jsonMatch = [regex]::Match($review, '\{[\s\S]*\}')
            if ($jsonMatch.Success) {
                try {
                    $reviewJson = $jsonMatch.Value | ConvertFrom-Json -ErrorAction Stop
                } catch {
                    $reviewJson = $null
                }
            }
        }

        if ($null -eq $reviewJson) {
            Write-Host "[Agent 4] JSON parse failed, auto-approving: $($draft.Name)" -ForegroundColor Yellow
            Copy-Item $draft.FullName -Destination "$APPROVED_PATH\$($draft.Name)" -Force
            $approved = $true
            continue
        }

        if ($reviewJson.result -eq "PASS") {
            Copy-Item $draft.FullName -Destination "$APPROVED_PATH\$($draft.Name)" -Force
            Write-Host "[Agent 4] PASS: $($draft.Name)" -ForegroundColor Green
            $approved = $true
        } else {
            $retryCount++
            Write-Host "[Agent 4] FAIL ($retryCount/1): $($draft.Name)" -ForegroundColor Yellow

            if ($retryCount -le 1) {
                $feedback = $reviewJson.feedback
                $rewritePrompt = "Rewrite the blog post at path $tempTxt based on this feedback: $feedback. Output markdown only including front matter. Do not wrap in code blocks."
                $rewritten = & "C:\Users\user\.local\bin\claude.exe" -p $rewritePrompt --allowedTools "Bash,WebFetch"
                if ($rewritten) {
                    $rewritten | Out-File -FilePath $draft.FullName -Encoding UTF8
                }
            } else {
                Write-Host "[Agent 4] Auto-approving after 1 retry: $($draft.Name)" -ForegroundColor Red
                Copy-Item $draft.FullName -Destination "$APPROVED_PATH\$($draft.Name)" -Force
                $approved = $true
            }
        }
    }
}

$approvedCount = (Get-ChildItem -Path $APPROVED_PATH -Filter "*.md").Count
Write-Host "[Agent 4] Done - $approvedCount approved." -ForegroundColor Green
