# PowerShell Script to Verify and Fix All Game Files
# Requirements:
# 1. First Display Ad: Horizontal (468x50) after navigation breadcrumbs
# 2. Second Display Ad: Vertical (300x600) in ad_box (right side of game_box)
# 3. Complete game_box structure with icon, title, rating, platform buttons, details
# 4. Carousel section
# 5. Get the Game section (if app links available)
# 6. Description section

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File
$referenceFile = "game\Five_Nights_at_Freddy_s_2.html"

Write-Host "Reading reference file: $referenceFile" -ForegroundColor Cyan
$referenceContent = Get-Content $referenceFile -Raw -Encoding UTF8

# Extract first horizontal ad structure from reference
$firstAdPattern = '(?s)(<!-- First Display Ad - Horizontal.*?</script>)'
if ($referenceContent -match $firstAdPattern) {
    $firstHorizontalAd = $matches[1]
    Write-Host "Found first horizontal ad structure" -ForegroundColor Green
} else {
    Write-Host "ERROR: Could not find first horizontal ad in reference file!" -ForegroundColor Red
    exit 1
}

$count = 0
$fixed = 0
$errors = 0
$issues = @()

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    Write-Host "`n[$count/$($gameFiles.Count)] Checking: $fileName" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        $changed = $false
        $fileIssues = @()
        
        # Check 1: First Display Ad - Should be horizontal (468x50) after navigation
        $hasFirstHorizontalAd = $content -match 'First Display Ad - Horizontal.*468x50'
        $hasFirstVerticalAd = $content -match 'First Display Ad.*vertical|ads-container vertical'
        
        if ($hasFirstVerticalAd) {
            $fileIssues += "First ad is vertical (should be horizontal)"
            Write-Host "  Issue: First ad is vertical" -ForegroundColor Yellow
        }
        
        if (-not $hasFirstHorizontalAd) {
            $fileIssues += "Missing first horizontal ad"
            Write-Host "  Issue: Missing first horizontal ad" -ForegroundColor Yellow
        }
        
        # Check 2: game_box structure
        $hasGameBox = $content -match '<div class="game_box">'
        if (-not $hasGameBox) {
            $fileIssues += "Missing game_box structure"
            Write-Host "  Issue: Missing game_box structure" -ForegroundColor Yellow
        }
        
        # Check 3: Second Display Ad - Should be vertical (300x600) in ad_box
        $hasSecondVerticalAd = $content -match 'Second Display Ad - Vertical.*300x600'
        $hasAdBox = $content -match 'class="ad_box"'
        
        if (-not $hasSecondVerticalAd -or -not $hasAdBox) {
            $fileIssues += "Missing second vertical ad in ad_box"
            Write-Host "  Issue: Missing second vertical ad in ad_box" -ForegroundColor Yellow
        }
        
        # Check 4: Carousel
        $hasCarousel = $content -match 'seeding_box'
        if (-not $hasCarousel) {
            $fileIssues += "Missing carousel section"
            Write-Host "  Issue: Missing carousel" -ForegroundColor Yellow
        }
        
        # Check 5: Description
        $hasDescription = $content -match '<h3>Description</h3>'
        if (-not $hasDescription) {
            $fileIssues += "Missing description section"
            Write-Host "  Issue: Missing description" -ForegroundColor Yellow
        }
        
        if ($fileIssues.Count -gt 0) {
            $issues += [PSCustomObject]@{
                File = $fileName
                Issues = $fileIssues -join "; "
            }
            Write-Host "  Total issues: $($fileIssues.Count)" -ForegroundColor Red
        } else {
            Write-Host "  OK - All checks passed" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files checked: $count" -ForegroundColor White
Write-Host "  Files with issues: $($issues.Count)" -ForegroundColor Yellow
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan

if ($issues.Count -gt 0) {
    Write-Host "`nFiles with issues:" -ForegroundColor Yellow
    $issues | Format-Table -AutoSize
}

