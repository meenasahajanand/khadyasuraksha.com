# PowerShell Script to Add Missing "Get the Game" Section After Carousel
# Pattern: After seeding_box closing, before Description

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$count = 0
$fixed = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        $hasCarousel = $content -match 'seeding_box'
        $hasGetGame = $content -match 'Get the Game'
        
        # Only process if has carousel but missing Get the Game
        if ($hasCarousel -and -not $hasGetGame) {
            Write-Host "[$count] $fileName - Adding Get the Game section" -ForegroundColor Yellow
            
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
            
            # Pattern: </div> </div> </div> </div> <div class="public_box"> <div class="box_three"> <h3>Description</h3>
            # This is after carousel, need to insert Get the Game before Description
            
            if ($content -match '(?s)(</div>\s*</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)') {
                $getGameLinks = ""
                if ($googlePlayLink) {
                    $getGameLinks += "                        <a href=`"$googlePlayLink`">`n<h4><i class=`"iconfont icon-google-play`"></i> <span>Google Play</span></h4>`n<p>Link provided by Google Play</p>`n</a>`n"
                }
                if ($appleStoreLink) {
                    $getGameLinks += "                        <a href=`"$appleStoreLink`">`n<h4><i class=`"iconfont icon-ios`"></i> <span>Apple Store</span></h4>`n<p>Link provided by Apple Store</p>`n</a>`n"
                }
                
                if ($getGameLinks) {
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
                    $content = $content -replace '(?s)(</div>\s*</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)', "$getGameSection`n            <div class=`"public_box`">`n                <div class=`"box_three`">`n                    <h3>Description</h3>"
                    
                    $content | Set-Content $filePath -Encoding UTF8 -NoNewline
                    Write-Host "  Fixed!" -ForegroundColor Green
                    $fixed++
                } else {
                    Write-Host "  No app links found" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  Pattern not found" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nSummary: Fixed $fixed files" -ForegroundColor Cyan

