# PowerShell Script to Remove Invalid Ad Script from All Files
# This invalid script might be blocking AdSense ads

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
        
        # Remove invalid script line
        if ($content -match 'securepubads\.g\.doubleclick\.net/tag/js/f\.txt') {
            # Remove the invalid script line (with or without comment)
            $content = $content -replace '(?m)^\s*<script async src="\.\.\/\.\.\/securepubads\.g\.doubleclick\.net/tag/js/f\.txt"\s*></script>\s*', ''
            $content = $content -replace '(?m)^\s*<script async src="\.\.\/securepubads\.g\.doubleclick\.net/tag/js/f\.txt"\s*></script>\s*', ''
            $content = $content -replace '(?m)^\s*<script async src="\.\.\/\.\.\/securepubads\.g\.doubleclick\.net/tag/js/f\.txt"\s*>\s*</script>\s*', ''
            
            # Also check if it's on the same line as AdSense script
            $content = $content -replace '(<script async src="https://pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js[^>]*>\s*</script>)\s*<script async src="[^"]*securepubads\.g\.doubleclick\.net[^"]*"\s*></script>', '$1'
            
            $changed = $true
            Write-Host "[$count] $fileName - Removing invalid script" -ForegroundColor Yellow
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

