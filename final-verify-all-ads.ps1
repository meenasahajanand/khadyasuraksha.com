# PowerShell Script to Verify Ad Placement - Final Check
# Count actual adsbygoogle ins tags

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$count = 0
$correct = 0
$issues = @()

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        # Count actual adsbygoogle ins tags (excluding script references)
        $adMatches = [regex]::Matches($content, '<ins class="adsbygoogle"')
        $adCount = $adMatches.Count
        
        # Check for first horizontal ad
        $hasFirstHorizontal = $content -match 'First Display Ad - Horizontal.*468x50'
        
        # Check for second vertical ad in ad_box
        $hasSecondVertical = $content -match 'Second Display Ad - Vertical.*300x600'
        $hasAdBox = $content -match 'class="ad_box"'
        
        $fileIssues = @()
        
        # Check ad count - should be exactly 2
        if ($adCount -ne 2) {
            $fileIssues += "Has $adCount ads (should be 2)"
        }
        
        # Check for duplicate horizontal ads
        $horizontalAdMatches = [regex]::Matches($content, 'First Display Ad - Horizontal')
        if ($horizontalAdMatches.Count -gt 1) {
            $fileIssues += "Has $($horizontalAdMatches.Count) horizontal ads (should be 1)"
        }
        
        if (-not $hasFirstHorizontal) {
            $fileIssues += "Missing first horizontal ad"
        }
        
        if (-not $hasSecondVertical -or -not $hasAdBox) {
            $fileIssues += "Missing second vertical ad in ad_box"
        }
        
        if ($fileIssues.Count -gt 0) {
            $issues += [PSCustomObject]@{
                File = $fileName
                AdCount = $adCount
                Issues = $fileIssues -join "; "
            }
            Write-Host "[$count] $fileName - AdCount: $adCount, Issues: $($fileIssues -join ', ')" -ForegroundColor Yellow
        } else {
            Write-Host "[$count] $fileName - OK (2 ads)" -ForegroundColor Green
            $correct++
        }
        
    } catch {
        Write-Host "[$count] $fileName - Error: $($_.Exception.Message)" -ForegroundColor Red
        $issues += [PSCustomObject]@{
            File = $fileName
            AdCount = "ERROR"
            Issues = "Error reading file"
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files: $count" -ForegroundColor White
Write-Host "  Correct (2 ads): $correct" -ForegroundColor Green
Write-Host "  Files with issues: $($issues.Count)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if ($issues.Count -gt 0 -and $issues.Count -le 20) {
    Write-Host "`nFiles with issues:" -ForegroundColor Yellow
    $issues | Format-Table -AutoSize
} elseif ($issues.Count -gt 20) {
    Write-Host "`nFirst 20 files with issues:" -ForegroundColor Yellow
    $issues | Select-Object -First 20 | Format-Table -AutoSize
    Write-Host "... and $($issues.Count - 20) more files" -ForegroundColor Yellow
}

