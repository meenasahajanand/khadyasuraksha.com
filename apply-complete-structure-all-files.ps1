# PowerShell Script to Apply Complete Structure to All Game Files
# Structure: game_box > carousel > Get the Game > Description
# Based on Five_Nights_at_Freddy_s_2.html

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$count = 0
$fixed = 0
$errors = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    Write-Host "[$count/$($gameFiles.Count)] Processing: $fileName" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        $changed = $false
        
        # Check structure
        $hasCarousel = $content -match 'seeding_box'
        $hasGetGame = $content -match 'Get the Game'
        
        # Extract game name for carousel images
        $gameName = ""
        if ($content -match '<span>([^<]+)</span></p>') {
            $gameName = $matches[1]
        }
        
        # Find carousel images
        $carouselImages = @()
        $imgMatches = [regex]::Matches($content, 'data-src="https://img\.civilitythegame\.com/Img/([^"]+\.jpg)"')
        foreach ($match in $imgMatches) {
            $imgName = $match.Groups[1].Value
            if ($imgName -notmatch 'lazyload\.png' -and $imgName -notmatch 'Icon/') {
                $gameNamePattern = $gameName -replace '[^a-zA-Z0-9]', '_'
                $fileNamePattern = $fileName -replace '\.html$', '' -replace '_', '_'
                if ($imgName -match $gameNamePattern -or $imgName -match [regex]::Escape($fileNamePattern)) {
                    $carouselImages += $imgName
                }
            }
        }
        
        # If no specific images, use first Img folder image
        if ($carouselImages.Count -eq 0) {
            $allImgMatches = [regex]::Matches($content, 'data-src="https://img\.civilitythegame\.com/Img/([^"]+\.jpg)"')
            foreach ($match in $allImgMatches) {
                $imgName = $match.Groups[1].Value
                if ($imgName -notmatch 'lazyload\.png' -and $imgName -notmatch 'Icon/') {
                    $carouselImages += $imgName
                    break
                }
            }
        }
        
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
        
        # Fix structure: after ad_box closing, should have carousel, Get the Game, then Description
        if ($content -match '(?s)(</script>\s*</div>\s*</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)') {
            $replacement = ""
            
            # Add carousel if missing
            if (-not $hasCarousel -and $carouselImages.Count -gt 0) {
                $carouselSlides = ""
                foreach ($img in $carouselImages) {
                    $carouselSlides += "                                <div class=`"swiper-slide`">`n<img  class=`"lazyload`" src=`"https://img.civilitythegame.com/Img/lazyload.png`" data-src=`"https://img.civilitythegame.com/Img/$img`" alt=`"`">`n</div>`n"
                }
                $replacement += @"
            </div>
            <!-- Carousel -->
            <div class="public_box">
                <div class="seeding_box">
                    <div class="seeding">
                        <div class="swiper">
                            <div class="swiper-wrapper">
$carouselSlides                            </div>
                        </div>
                    </div>
                </div>
            </div>
"@
            }
            
            # Add Get the Game if missing
            if (-not $hasGetGame -and ($googlePlayLink -or $appleStoreLink)) {
                $getGameLinks = ""
                if ($googlePlayLink) {
                    $getGameLinks += "                        <a href=`"$googlePlayLink`">`n<h4><i class=`"iconfont icon-google-play`"></i> <span>Google Play</span></h4>`n<p>Link provided by Google Play</p>`n</a>`n"
                }
                if ($appleStoreLink) {
                    $getGameLinks += "                        <a href=`"$appleStoreLink`">`n<h4><i class=`"iconfont icon-ios`"></i> <span>Apple Store</span></h4>`n<p>Link provided by Apple Store</p>`n</a>`n"
                }
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
            
            if ($replacement) {
                $content = $content -replace '(?s)(</script>\s*</div>\s*</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)', "$replacement`n            <div class=`"public_box`">`n                <div class=`"box_three`">`n                    <h3>Description</h3>"
                $changed = $true
                Write-Host "  Added missing sections" -ForegroundColor Green
            }
        }
        
        # Save if changed
        if ($changed) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "  Fixed!" -ForegroundColor Green
            $fixed++
        } else {
            Write-Host "  Already correct" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
    
    Write-Host ""
}

Write-Host "Summary: Fixed $fixed files" -ForegroundColor Cyan

