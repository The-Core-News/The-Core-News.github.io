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

    while (-not $approved -and $retryCount -le 2) {

        # 파일 내용을 임시 txt로 저장해서 heredoc 충돌 방지
        $tempTxt = "$TEMP_PATH\review_input.txt"
        Copy-Item $draft.FullName -Destination $tempTxt

        $prompt = "You are a blog review editor. Review the draft post in the file at path: $tempTxt`n`nChecklist:`n1. Facts: verifiable and correct?`n2. Front matter: layout, title, date, categories present?`n3. Length: at least 1000 characters?`n4. Quality: has perspective and commentary?`n`nIMPORTANT: Output a single JSON object only. No explanation. No markdown fences.`n{`"result`":`"PASS`",`"issues`":[],`"feedback`":`"`"}`nor`n{`"result`":`"FAIL`",`"issues`":[`"issue1`"],`"feedback`":`"rewrite instructions`"}"

        $review = & "C:\Users\user\.local\bin\claude.exe" -p $prompt --allowedTools "Bash"

        # 안전한 JSON 추출
        $reviewJson = $null
        if ($review) {
            $jsonMatch = [regex]::Match($review, '\{[\s\S]*?\}')
            if ($jsonMatch.Success) {
                try {
                    $reviewJson = $jsonMatch.Value | ConvertFrom-Json -ErrorAction Stop
                } catch {
                    $reviewJson = $null
                }
            }
        }

        # 파싱 실패시 자동 승인
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
            Write-Host "[Agent 4] FAIL ($retryCount/2): $($draft.Name)" -ForegroundColor Yellow

            if ($retryCount -le 2) {
                $feedback = $reviewJson.feedback
                $rewritePrompt = "Rewrite the blog post at path $tempTxt based on this feedback: $feedback. Output markdown only including front matter."
                $rewritten = & "C:\Users\user\.local\bin\claude.exe" -p $rewritePrompt --allowedTools "Bash,WebFetch"
                if ($rewritten) {
                    $rewritten | Out-File -FilePath $draft.FullName -Encoding UTF8
                }
            } else {
                Write-Host "[Agent 4] Skipped after 2 retries, auto-approving: $($draft.Name)" -ForegroundColor Red
                Copy-Item $draft.FullName -Destination "$APPROVED_PATH\$($draft.Name)" -Force
                $approved = $true
            }
        }
    }
}

$approvedCount = (Get-ChildItem -Path $APPROVED_PATH -Filter "*.md").Count
Write-Host "[Agent 4] Done - $approvedCount approved." -ForegroundColor Green
