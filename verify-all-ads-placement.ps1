# PowerShell Script to Verify Ad Placement in All Game Files
# Should have exactly 2 display ads:
# 1. First Display Ad - Horizontal (468x50) after navigation
# 2. Second Display Ad - Vertical (300x600) in ad_box

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
        
        # Count adsbygoogle instances
        $adMatches = [regex]::Matches($content, 'adsbygoogle.*data-ad-slot')
        $adCount = $adMatches.Count
        
        # Check for first horizontal ad
        $hasFirstHorizontal = $content -match 'First Display Ad - Horizontal.*468x50'
        
        # Check for second vertical ad in ad_box
        $hasSecondVertical = $content -match 'Second Display Ad - Vertical.*300x600'
        $hasAdBox = $content -match 'class="ad_box"'
        
        $fileIssues = @()
        
        # Check ad count
        if ($adCount -ne 2) {
            $fileIssues += "Has $adCount ads (should be 2)"
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
            Write-Host "[$count] $fileName - Issues: $($fileIssues -join ', ')" -ForegroundColor Yellow
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

if ($issues.Count -gt 0) {
    Write-Host "`nFiles with issues:" -ForegroundColor Yellow
    $issues | Format-Table -AutoSize
}

