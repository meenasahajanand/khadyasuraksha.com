# PowerShell Script to Remove Vertical Ad After Header from All Files
# This ad should not be there - only horizontal ad after navigation should exist

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
        
        # Remove vertical ad after header
        if ($content -match '(?s)(<!-- First Display Ad - After Header -->.*?ads-container vertical.*?</script>\s*</div>\s*<div class="main container">)') {
            $content = $content -replace '(?s)(<!-- First Display Ad - After Header -->.*?ads-container vertical.*?</script>\s*</div>\s*)', ''
            $changed = $true
            Write-Host "[$count] $fileName - Removed vertical ad after header" -ForegroundColor Yellow
        }
        
        if ($changed) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "  Fixed!" -ForegroundColor Green
            $fixed++
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

