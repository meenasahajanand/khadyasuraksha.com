# PowerShell Script to Fix First Display Ad - Change from Vertical to Horizontal
# Replace vertical ad after header with horizontal ad (468x50) after navigation

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File
$referenceFile = "game\Five_Nights_at_Freddy_s_2.html"

Write-Host "Reading reference file: $referenceFile" -ForegroundColor Cyan
$referenceContent = Get-Content $referenceFile -Raw -Encoding UTF8

# Extract first horizontal ad structure from reference
$firstAdPattern = '(?s)(<!-- First Display Ad - Horizontal.*?</script>\s*</div>\s*</div>)'
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

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        $changed = $false
        
        # Check if file has vertical ad after header
        $hasVerticalAd = $content -match '(?s)(<!-- First Display Ad - After Header.*?ads-container vertical.*?</script>\s*</div>\s*</div>)'
        $hasHorizontalAd = $content -match 'First Display Ad - Horizontal.*468x50'
        
        # Only fix if has vertical ad or missing horizontal ad
        if ($hasVerticalAd -or -not $hasHorizontalAd) {
            Write-Host "[$count] $fileName - Fixing first ad..." -ForegroundColor Yellow
            
            # Find navigation breadcrumbs
            if ($content -match '(?s)(<p class="navigation">.*?</p>)') {
                $navigation = $matches[1]
                
                # Remove vertical ad after header if exists
                if ($hasVerticalAd) {
                    $content = $content -replace '(?s)(<!-- First Display Ad - After Header.*?ads-container vertical.*?</script>\s*</div>\s*</div>\s*<div class="main container">)', '<div class="main container">'
                    $changed = $true
                    Write-Host "  Removed vertical ad after header" -ForegroundColor Yellow
                }
                
                # Add horizontal ad after navigation if not present
                if (-not $hasHorizontalAd) {
                    # Find the section div after navigation
                    if ($content -match '(?s)(<p class="navigation">.*?</p>\s*)(<div class="section">|<div class="public_box">)') {
                        $beforeSection = $matches[1]
                        $sectionStart = $matches[2]
                        
                        # Insert horizontal ad after navigation
                        $horizontalAdInsert = $beforeSection + $firstHorizontalAd + "`n            " + $sectionStart
                        $content = $content -replace '(?s)(<p class="navigation">.*?</p>\s*)(<div class="section">|<div class="public_box">)', $horizontalAdInsert
                        $changed = $true
                        Write-Host "  Added horizontal ad after navigation" -ForegroundColor Green
                    }
                }
            }
            
            if ($changed) {
                $content | Set-Content $filePath -Encoding UTF8 -NoNewline
                Write-Host "  Fixed!" -ForegroundColor Green
                $fixed++
            }
        } else {
            Write-Host "[$count] $fileName - Already correct" -ForegroundColor Green
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

