# PowerShell Script to Fix Game Pages Structure
# Remove ad_box from box_three pages

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$count = 0
$fixed = 0
$errors = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    Write-Host "[$count/$($gameFiles.Count)] Processing: $($file.Name)" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        
        # Check if file has game_box structure
        $hasGameBox = $content -match '<div class="game_box">'
        
        if (-not $hasGameBox) {
            # File has box_three structure - remove ad_box if it's inside get_app_box
            # Pattern: </a> followed by ad_box inside get_app_box
            $pattern = '(?s)(</a>\s*</div>\s*<div class="ad_box">.*?</div>\s*</div>\s*</div>\s*</div>)'
            if ($content -match $pattern) {
                # Remove ad_box from inside box_three
                $content = $content -replace $pattern, '</a>                    </div>                </div>            </div>'
                Write-Host "  Removed ad_box from box_three structure" -ForegroundColor Green
                $fixed++
            }
        }
        
        # Save only if content changed
        if ($content -ne $originalContent) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "  Fixed!" -ForegroundColor Green
        } else {
            Write-Host "  No changes needed" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
    
    Write-Host ""
}

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files: $count" -ForegroundColor White
Write-Host "  Fixed: $fixed" -ForegroundColor Green
Write-Host "  Errors: $errors" -ForegroundColor Red
