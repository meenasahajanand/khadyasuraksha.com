# PowerShell Script to Fix All Game Files Structure
# Match Five_Nights_at_Freddy_s_2.html structure exactly:
# 1. game_box with ad_box
# 2. seeding_box (carousel)
# 3. box_three "Get the Game"
# 4. box_three "Description"

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
        
        # Check if file has proper structure
        $hasGameBox = $content -match '<div class="game_box">'
        $hasCarousel = $content -match 'seeding_box'
        $hasGetGame = $content -match 'Get the Game'
        $hasDescription = $content -match '<h3>Description</h3>'
        
        if ($hasGameBox -and $hasDescription) {
            # Extract game name
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
                    # Check if image matches game name pattern
                    $gameNamePattern = $gameName -replace '[^a-zA-Z0-9]', '_'
                    $fileNamePattern = $fileName -replace '\.html$', '' -replace '_', '_'
                    if ($imgName -match $gameNamePattern -or $imgName -match [regex]::Escape($fileNamePattern)) {
                        $carouselImages += $imgName
                    }
                }
            }
            
            # If no specific images, try to find any Img folder images (first 3)
            if ($carouselImages.Count -eq 0) {
                $allImgMatches = [regex]::Matches($content, 'data-src="https://img\.civilitythegame\.com/Img/([^"]+\.jpg)"')
                foreach ($match in $allImgMatches) {
                    $imgName = $match.Groups[1].Value
                    if ($imgName -notmatch 'lazyload\.png' -and $imgName -notmatch 'Icon/') {
                        $carouselImages += $imgName
                        if ($carouselImages.Count -ge 3) { break }
                    }
                }
            }
            
            # Find Google Play and Apple Store links
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
            
            # Extract Description content
            $descriptionContent = ""
            if ($content -match '(?s)<div class="box_three">\s*<h3>Description</h3>\s*<div class="dec">(.*?)</div>\s*</div>\s*</div>') {
                $descriptionContent = $matches[1]
            }
            
            # Build the correct structure
            # Pattern: </div> </div> </div> (end of game_box) should be followed by carousel, Get the Game, then Description
            
            # Check if carousel is missing
            if (-not $hasCarousel -and $carouselImages.Count -gt 0) {
                $carouselSlides = ""
                foreach ($img in $carouselImages) {
                    $carouselSlides += "                                <div class=`"swiper-slide`">`n<img  class=`"lazyload`" src=`"https://img.civilitythegame.com/Img/lazyload.png`" data-src=`"https://img.civilitythegame.com/Img/$img`" alt=`"`">`n</div>`n"
                }
                
                $carouselSection = @"
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
                
                # Insert carousel before Description
                if ($content -match '(?s)(</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)') {
                    $content = $content -replace '(?s)(</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)', "`n            </div>`n$carouselSection            <div class=`"public_box`">`n                <div class=`"box_three`">`n                    <h3>Description</h3>"
                    $changed = $true
                    Write-Host "  Added carousel section" -ForegroundColor Green
                }
            }
            
            # Check if "Get the Game" section is missing
            if (-not $hasGetGame -and ($googlePlayLink -or $appleStoreLink)) {
                $getGameLinks = ""
                if ($googlePlayLink) {
                    $getGameLinks += "                        <a href=`"$googlePlayLink`">`n<h4><i class=`"iconfont icon-google-play`"></i> <span>Google Play</span></h4>`n<p>Link provided by Google Play</p>`n</a>`n"
                }
                if ($appleStoreLink) {
                    $getGameLinks += "                        <a href=`"$appleStoreLink`">`n<h4><i class=`"iconfont icon-ios`"></i> <span>Apple Store</span></h4>`n<p>Link provided by Apple Store</p>`n</a>`n"
                }
                
                $getGameSection = @"
            <div class="public_box">
                <div class="box_three">
                    <h3>Get the Game</h3>
                    <div class="get_app_box">

$getGameLinks                    </div>
</div>
                </div>
            </div>

"@
                
                # Insert "Get the Game" before Description
                if ($content -match '(?s)(</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)') {
                    $content = $content -replace '(?s)(</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)', "`n            </div>`n$getGameSection            <div class=`"public_box`">`n                <div class=`"box_three`">`n                    <h3>Description</h3>"
                    $changed = $true
                    Write-Host "  Added Get the Game section" -ForegroundColor Green
                } elseif ($content -match '(?s)(<!-- Carousel -->.*?</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)') {
                    # If carousel exists, insert after carousel
                    $content = $content -replace '(?s)(<!-- Carousel -->.*?</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)', "`$1`n$getGameSection            <div class=`"public_box`">`n                <div class=`"box_three`">`n                    <h3>Description</h3>"
                    $changed = $true
                    Write-Host "  Added Get the Game section" -ForegroundColor Green
                }
            }
            
            # Ensure proper closing of game_box
            if ($content -match '(?s)(</div>\s*</div>\s*</div>\s*<div class="public_box">)') {
                $content = $content -replace '(?s)(</div>\s*</div>\s*</div>\s*<div class="public_box">)', "`n            </div>`n            <div class=`"public_box`">"
                $changed = $true
            }
        }
        
        # Save if changed
        if ($changed) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "  Fixed!" -ForegroundColor Green
            $fixed++
        } else {
            Write-Host "  No changes needed" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files: $count" -ForegroundColor White
Write-Host "  Fixed: $fixed" -ForegroundColor Green
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan

