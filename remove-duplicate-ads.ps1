# PowerShell Script to Remove Duplicate Horizontal Ads
# Keep only first horizontal ad after navigation

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$count = 0
$fixed = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        
        # Find all horizontal ads
        $adPattern = '(?s)(<!-- First Display Ad - Horizontal \(468x50\) -->\s*<div class="s_box"[^>]*>.*?</div>\s*</div>\s*</div>)'
        $matches = [regex]::Matches($content, $adPattern)
        
        if ($matches.Count -gt 1) {
            Write-Host "[$count] $fileName - Found $($matches.Count) horizontal ads, removing duplicates..." -ForegroundColor Yellow
            
            # Keep first, remove all others
            for ($i = $matches.Count - 1; $i -ge 1; $i--) {
                $content = $content -replace [regex]::Escape($matches[$i].Value), ''
            }
            
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "  Removed $($matches.Count - 1) duplicate ad(s)" -ForegroundColor Green
            $fixed++
        }
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nSummary: Fixed $fixed files" -ForegroundColor Cyan

