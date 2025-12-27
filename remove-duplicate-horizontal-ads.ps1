# PowerShell Script to Remove Duplicate Horizontal Ads
# Each file should have only 1 horizontal ad after navigation

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$count = 0
$fixed = 0
$errors = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        $changed = $false
        
        # Count horizontal ads
        $horizontalAdMatches = [regex]::Matches($content, 'First Display Ad - Horizontal.*?468x50')
        $horizontalAdCount = $horizontalAdMatches.Count
        
        if ($horizontalAdCount -gt 1) {
            Write-Host "[$count] $fileName - Found $horizontalAdCount horizontal ads, removing duplicates..." -ForegroundColor Yellow
            
            # Find all horizontal ad sections
            $pattern = '(?s)(<!-- First Display Ad - Horizontal.*?</script>\s*</div>\s*</div>)'
            $matches = [regex]::Matches($content, $pattern)
            
            if ($matches.Count -gt 1) {
                # Keep only the first one, remove the rest
                $firstAd = $matches[0].Value
                $remainingContent = $content
                
                # Remove all occurrences
                $remainingContent = $remainingContent -replace $pattern, ''
                
                # Find navigation and insert first ad after it
                if ($remainingContent -match '(?s)(<p class="navigation">.*?</p>\s*)(<div class="public_box">|<div class="section">)') {
                    $navigation = $matches[0].Groups[1].Value
                    $afterNav = $matches[0].Groups[2].Value
                    
                    # Insert first ad after navigation
                    $newContent = $navigation + $firstAd + "`n            " + $afterNav
                    $remainingContent = $remainingContent -replace '(?s)(<p class="navigation">.*?</p>\s*)(<div class="public_box">|<div class="section">)', $newContent
                    
                    $content = $remainingContent
                    $changed = $true
                }
            }
        }
        
        if ($changed) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "  Fixed!" -ForegroundColor Green
            $fixed++
        } else {
            if ($horizontalAdCount -eq 1) {
                Write-Host "[$count] $fileName - OK (1 horizontal ad)" -ForegroundColor Green
            }
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files: $count" -ForegroundColor White
Write-Host "  Fixed: $fixed" -ForegroundColor Green
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan

