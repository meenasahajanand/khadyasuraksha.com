# PowerShell Script to Fix ALL Game Files - Complete Structure
# Fix closing tags and add missing sections

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
        
        # Check what's missing
        $hasCarousel = $content -match 'seeding_box'
        $hasGetGame = $content -match 'Get the Game'
        
        # Only process if missing sections
        if (-not $hasCarousel -or -not $hasGetGame) {
            Write-Host "[$count] $fileName - Fixing..." -ForegroundColor Yellow
            
            # Find app links
            $googlePlayLink = ""
            $appleStoreLink = ""
            if ($content -match 'play\.google\.com/store/apps/details\?id=([^&"]+)') {
                $appId = $matches[1]
                $googlePlayLink = "https://play.google.com/store/apps/details?id=$appId&amp;gl=AT"
            }
            if ($content -match 'apps\.apple\.com/app/id(\d+)') {
                $appId = $matches[1]
                $appleStoreLink = "https://apps.apple.com/app/id$appId"
            }
            
            # Pattern 1: </script> </div> <div class="public_box"> <div class="box_three"> <h3>Description</h3>
            # Need to fix: add missing closing divs, then add carousel and Get the Game
            
            if ($content -match '(?s)(</script>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)') {
                $replacement = "</script>`n                            </div>`n                        </div>`n                    </div>`n            </div>`n"
                
                # Add carousel if missing
                if (-not $hasCarousel) {
                    $replacement += @"
            <!-- Carousel -->
            <div class="public_box">
                <div class="seeding_box">
                    <div class="seeding">
                        <div class="swiper">
                            <div class="swiper-wrapper">
                                <div class="swiper-slide">
<img  class="lazyload" src="https://img.civilitythegame.com/Img/lazyload.png" data-src="https://img.civilitythegame.com/Img/lazyload.png" alt="">
</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
"@
                }
                
                # Add Get the Game if missing
                if (-not $hasGetGame) {
                    $getGameLinks = ""
                    if ($googlePlayLink) {
                        $getGameLinks += "                        <a href=`"$googlePlayLink`">`n<h4><i class=`"iconfont icon-google-play`"></i> <span>Google Play</span></h4>`n<p>Link provided by Google Play</p>`n</a>`n"
                    }
                    if ($appleStoreLink) {
                        $getGameLinks += "                        <a href=`"$appleStoreLink`">`n<h4><i class=`"iconfont icon-ios`"></i> <span>Apple Store</span></h4>`n<p>Link provided by Apple Store</p>`n</a>`n"
                    }
                    
                    if ($getGameLinks) {
                        $replacement += @"
            <div class="public_box">
                <div class="box_three">
                    <h3>Get the Game</h3>
                    <div class="get_app_box">

$getGameLinks                    </div>
</div>
                </div>
            </div>
"@
                    }
                }
                
                $content = $content -replace '(?s)(</script>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)', "$replacement`n            <div class=`"public_box`">`n                <div class=`"box_three`">`n                    <h3>Description</h3>"
                
                $content | Set-Content $filePath -Encoding UTF8 -NoNewline
                Write-Host "  Fixed!" -ForegroundColor Green
                $fixed++
            } else {
                Write-Host "  Pattern not found - checking structure" -ForegroundColor Red
            }
        } else {
            Write-Host "  Already complete" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`nSummary: Fixed $fixed files" -ForegroundColor Cyan

