# PowerShell Script to Check and Restore All Game Files
# Based on live URL structure: https://playnovapro.com/game/Five_Nights_at_Freddy_s_2.html

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$firstHorizontalAd = @"
            <!-- First Display Ad - Horizontal (468x50) -->
            <div class="s_box" style="margin-bottom: 15px;">
                <div style="text-align: center; padding: 10px;">
                    <p style="text-align: center; margin-bottom: 10px; font-size: 12px; color: #999;">Advertisement</p>
                    <ins class="adsbygoogle"
                         style="display:inline-block; width: 468px; height: 50px;"
                         data-ad-client="ca-pub-7354377815781712"
                         data-ad-slot="7523911922"
                         data-ad-format="auto"
                         data-full-width-responsive="true"></ins>
                    <script>
                         (adsbygoogle = window.adsbygoogle || []).push({});
                    </script>
                </div>
            </div>
"@

$verticalAdInAdBox = @"
                    <div class="ad_box">
                        <div class="ad">
                            <p style="text-align: center; margin-bottom: 10px; font-size: 12px; color: #999; font-weight: 700;">Advertisement</p>
                            <div style="width: 100%; max-width: 300px; margin: 0 auto;">
                                <!-- Second Display Ad - Vertical (300x600) -->
                                <ins class="adsbygoogle"
                                     style="display:block; width: 300px; height: 600px;"
                                     data-ad-client="ca-pub-7354377815781712"
                                     data-ad-slot="1150075265"
                                     data-ad-format="auto"
                                     data-full-width-responsive="true"></ins>
                                <script>
                                     (adsbygoogle = window.adsbygoogle || []).push({});
                                </script>
                            </div>
                        </div>
                    </div>
"@

$count = 0
$needsGameBox = @()
$needsGetGame = @()
$needsCarousel = @()
$needsAdBox = @()
$fixed = 0
$errors = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    Write-Host "[$count/$($gameFiles.Count)] Checking: $fileName" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        # Check what's missing
        $hasGameBox = $content -match '<div class="game_box">'
        $hasBoxThree = $content -match '<div class="box_three">'
        $hasGetGame = $content -match 'Get the Game|get_app_box'
        $hasCarousel = $content -match 'seeding_box'
        $hasAdBox = $content -match '<div class="ad_box">'
        $hasHorizontalAd = $content -match 'First Display Ad - Horizontal \(468x50\)'
        
        $issues = @()
        
        # Check horizontal ad
        if (-not $hasHorizontalAd) {
            $issues += "Missing horizontal ad"
        }
        
        # Determine structure type
        if ($hasGameBox) {
            # File has game_box - should have ad_box, carousel, Get the Game, Description
            if (-not $hasAdBox) {
                $issues += "Missing ad_box"
                $needsAdBox += $fileName
            }
            if (-not $hasCarousel) {
                $issues += "Missing carousel"
                $needsCarousel += $fileName
            }
            if (-not $hasGetGame) {
                $issues += "Missing Get the Game section"
                $needsGetGame += $fileName
            }
        } elseif ($hasBoxThree) {
            # File has box_three - check if it should have game_box
            # If it has Description but no Get the Game, it might need game_box
            if ($content -match 'Description' -and -not $hasGetGame) {
                $issues += "Might need game_box structure (has Description but no Get the Game)"
                $needsGameBox += $fileName
            } elseif (-not $hasGetGame) {
                $issues += "Missing Get the Game section"
                $needsGetGame += $fileName
            }
        } else {
            # No structure at all - needs game_box
            $issues += "Missing game_box structure"
            $needsGameBox += $fileName
        }
        
        if ($issues.Count -gt 0) {
            Write-Host "  Issues found: $($issues -join ', ')" -ForegroundColor Yellow
        } else {
            Write-Host "  OK" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files checked: $count" -ForegroundColor White
Write-Host "  Files needing game_box: $($needsGameBox.Count)" -ForegroundColor Yellow
Write-Host "  Files needing Get the Game: $($needsGetGame.Count)" -ForegroundColor Yellow
Write-Host "  Files needing carousel: $($needsCarousel.Count)" -ForegroundColor Yellow
Write-Host "  Files needing ad_box: $($needsAdBox.Count)" -ForegroundColor Yellow
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan

if ($needsGameBox.Count -gt 0) {
    Write-Host "`nFiles that might need game_box structure:" -ForegroundColor Yellow
    $needsGameBox | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
}

if ($needsGetGame.Count -gt 0) {
    Write-Host "`nFiles missing Get the Game section:" -ForegroundColor Yellow
    $needsGetGame | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
}

if ($needsCarousel.Count -gt 0) {
    Write-Host "`nFiles missing carousel:" -ForegroundColor Yellow
    $needsCarousel | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
}

if ($needsAdBox.Count -gt 0) {
    Write-Host "`nFiles missing ad_box:" -ForegroundColor Yellow
    $needsAdBox | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
}

