# PowerShell Script to Fix Ad Sizes to Match AdSense Ad Units
# First ad: 468x60 (2inter_2512) - slot 7523911922
# Second ad: 300x600 (2display_2512) - slot 1150075265

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
        
        # Fix first ad (468x60) - slot 7523911922
        if ($content -match 'data-ad-slot="7523911922"') {
            # Replace with correct format
            $content = $content -replace '(?s)(<ins class="adsbygoogle"[^>]*data-ad-slot="7523911922"[^>]*style="[^"]*width:\s*468px[^"]*height:\s*50px[^"]*"[^>]*>)', '<ins class="adsbygoogle" style="display:inline-block;width:468px;height:60px" data-ad-client="ca-pub-7354377815781712" data-ad-slot="7523911922"></ins>'
            
            # Also fix if it has data-ad-format
            $content = $content -replace '(?s)(<ins class="adsbygoogle"[^>]*style="[^"]*width:\s*468px[^"]*height:\s*50px[^"]*"[^>]*data-ad-client="ca-pub-7354377815781712"[^>]*data-ad-slot="7523911922"[^>]*>)', '<ins class="adsbygoogle" style="display:inline-block;width:468px;height:60px" data-ad-client="ca-pub-7354377815781712" data-ad-slot="7523911922"></ins>'
            
            $changed = $true
        }
        
        # Fix second ad (300x600) - slot 1150075265
        if ($content -match 'data-ad-slot="1150075265"') {
            # Replace with correct format
            $content = $content -replace '(?s)(<ins class="adsbygoogle"[^>]*data-ad-slot="1150075265"[^>]*style="[^"]*width:\s*300px[^"]*height:\s*600px[^"]*"[^>]*>)', '<ins class="adsbygoogle" style="display:inline-block;width:300px;height:600px" data-ad-client="ca-pub-7354377815781712" data-ad-slot="1150075265"></ins>'
            
            # Also fix if it has data-ad-format
            $content = $content -replace '(?s)(<ins class="adsbygoogle"[^>]*style="[^"]*width:\s*300px[^"]*height:\s*600px[^"]*"[^>]*data-ad-client="ca-pub-7354377815781712"[^>]*data-ad-slot="1150075265"[^>]*>)', '<ins class="adsbygoogle" style="display:inline-block;width:300px;height:600px" data-ad-client="ca-pub-7354377815781712" data-ad-slot="1150075265"></ins>'
            
            $changed = $true
        }
        
        if ($changed) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "[$count] $fileName - Fixed ad sizes" -ForegroundColor Green
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

