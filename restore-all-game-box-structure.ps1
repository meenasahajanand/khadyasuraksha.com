# PowerShell Script to Restore game_box Structure to All Game Files
# Based on Five_Nights_at_Freddy_s_2.html structure

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
$fixed = 0
$skipped = 0
$errors = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    Write-Host "[$count/$($gameFiles.Count)] Processing: $fileName" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        
        # Skip if already has game_box structure
        if ($content -match '<div class="game_box">' -and $content -match 'game_details' -and $content -match 'Get the Game') {
            Write-Host "  Already has game_box structure, skipping..." -ForegroundColor Yellow
            $skipped++
            continue
        }
        
        # Extract game name from navigation
        $gameName = ""
        if ($content -match '<span>([^<]+)</span></p>') {
            $gameName = $matches[1]
        } else {
            # Extract from file name
            $gameName = $fileName -replace '\.html$', '' -replace '_', ' '
        }
        
        # Find game icon URL from Recommended Games section
        $iconUrl = ""
        $iconPattern = "data-src=`"https://img\.civilitythegame\.com/Icon/([^`"]+)`".*alt=`"$([regex]::Escape($gameName))`""
        if ($content -match $iconPattern) {
            $iconHash = $matches[1]
            $iconUrl = "https://img.civilitythegame.com/Icon/$iconHash"
        } else {
            # Try to find any icon URL in Recommended Games
            if ($content -match 'data-src=`"https://img\.civilitythegame\.com/Icon/([^`"]+\.jpg)`"') {
                $iconHash = $matches[1]
                $iconUrl = "https://img.civilitythegame.com/Icon/$iconHash"
            }
        }
        
        # Find carousel images
        $carouselImages = @()
        if ($content -match 'data-src=`"https://img\.civilitythegame\.com/Img/([^`"]+\.jpg)`"') {
            $allMatches = [regex]::Matches($content, 'data-src=`"https://img\.civilitythegame\.com/Img/([^`"]+\.jpg)`"')
            foreach ($match in $allMatches) {
                if ($match.Groups[1].Value -notmatch 'lazyload\.png' -and $match.Groups[1].Value -notmatch 'Icon/') {
                    $carouselImages += $match.Groups[1].Value
                }
            }
        }
        
        # Find Google Play and Apple Store links
        $googlePlayLink = ""
        $appleStoreLink = ""
        if ($content -match 'play\.google\.com/store/apps/details\?id=([^&`"]+)') {
            $appId = $matches[1]
            $googlePlayLink = "https://play.google.com/store/apps/details?id=$appId&amp;gl=AT"
        }
        if ($content -match 'apps\.apple\.com/app/id(\d+)') {
            $appId = $matches[1]
            $appleStoreLink = "https://apps.apple.com/app/id$appId"
        }
        
        # Check if file has game_box or box_three
        $hasGameBox = $content -match '<div class="game_box">'
        $hasBoxThree = $content -match '<div class="box_three">'
        
        if (-not $hasGameBox -and $hasBoxThree) {
            # Need to convert box_three to game_box structure
            # Extract Description content
            $descriptionContent = ""
            if ($content -match '(?s)<div class="box_three">\s*<h3>Description</h3>\s*<div class="dec">(.*?)</div>\s*</div>\s*</div>') {
                $descriptionContent = $matches[1]
            }
            
            # Build game_box structure
            $gameBoxStructure = @"
            <div class="public_box">
                <div class="game_box">
                    <div class="game">
                        <div class="mm_t">
                            <div class="img">
                                <img class="lazyLoad" src="$iconUrl" alt="$gameName">
                            </div>
                            <div class="ml_t">
                                <h3>$gameName</h3>
                                <div class="g_a_link">
                                    <div class="buttons">
                                        <div id="link"><i class="iconfont icon-zan"></i></div>
                                        <div id="dislink"><i class="iconfont icon-zanxia"></i></div>
                                    </div>
                                    <div class="rating-bar">
                                        <div class="rating-name_box">
                                            <p><span>100%</span><span>like</span></p>
                                            <p><span>0%</span><span>dislike</span></p>
                                        </div>
                                        <div class="article">
                                            <div class="c" style="width: 100%"></div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="game_details">
                            <div class="buttons">
                                <span class="btn active" onclick="showHide(this,1)">Android</span>
<span class="btn" onclick="showHide(this,2)">iOS</span>


                            </div>
                            <div class="details_box">
                                <ul class="active">
                                    <li>
                                        <h3>File Size:</h3>
                                        <p>{i_game_Android_Size}</p>
                                    </li>
                                    <li>
                                        <h3>Updated Date:</h3>
                                        <p>{i_game_Android_Date}</p>
                                    </li>
                                    <li>
                                        <h3>Version:</h3>
                                        <p>{i_game_Android_Version}</p>
                                    </li>
                                    <li>
                                        <h3>Developer:</h3>
                                        <p>{i_game_Developer}</p>
                                    </li>
                                </ul>
                                <ul class="">
                                    <li>
                                        <h3>File Size:</h3>
                                        <p>{i_game_iOS_Size}</p>
                                    </li>
                                    <li>
                                        <h3>Updated Date:</h3>
                                        <p>{i_game_iOS_Date}</p>
                                    </li>
                                    <li>
                                        <h3>Version:</h3>
                                        <p>{i_game_iOS_Version}</p>
                                    </li>
                                    <li>
                                        <h3>Developer:</h3>
                                        <p>{i_game_Developer}</p>
                                    </li>
                                </ul>
                                <ul class="">
                                    <li>
                                        <h3>File Size:</h3>
                                        <p>{i_game_Windows_Size}</p>
                                    </li>
                                    <li>
                                        <h3>Updated Date:</h3>
                                        <p>{i_game_Windows_Date}</p>
                                    </li>
                                    <li>
                                        <h3>Version:</h3>
                                        <p>{i_game_Windows_Version}</p>
                                    </li>
                                    <li>
                                        <h3>Developer:</h3>
                                        <p>{i_game_Developer}</p>
                                    </li>
                                </ul>

                            </div>
                            <script>

                                function showHide(_this, index) {
                                    if (!_this.classList.contains("active")) {
                                        document.querySelector(".buttons > .active").classList.remove("active");
                                        _this.classList.add("active");
                                        document.querySelector('.details_box > .active').classList.remove("active");
                                        document.querySelector('.details_box > ul:nth-child(' + index + ')').classList.add("active")
                                    }
                                }

                            </script>
                        </div>
                    </div>
$verticalAdInAdBox
            </div>
"@
            
            # Build carousel section
            $carouselSection = ""
            if ($carouselImages.Count -gt 0) {
                $carouselSlides = ""
                foreach ($img in $carouselImages) {
                    $carouselSlides += "<div class=`"swiper-slide`">`n<img  class=`"lazyload`" src=`"https://img.civilitythegame.com/Img/lazyload.png`" data-src=`"https://img.civilitythegame.com/Img/$img`" alt=`"`">`n</div>`n"
                }
                $carouselSection = @"
            <!--轮播-->
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
            
            # Build Get the Game section
            $getGameSection = ""
            if ($googlePlayLink -or $appleStoreLink) {
                $getGameLinks = ""
                if ($googlePlayLink) {
                    $getGameLinks += "<a href=`"$googlePlayLink`">`n<h4><i class=`"iconfont icon-google-play`"></i> <span>Google Play</span></h4>`n<p>Link provided by Google Play</p>`n</a>`n"
                }
                if ($appleStoreLink) {
                    $getGameLinks += "<a href=`"$appleStoreLink`">`n<h4><i class=`"iconfont icon-ios`"></i> <span>Apple Store</span></h4>`n<p>Link provided by Apple Store</p>`n</a>`n"
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
            }
            
            # Replace box_three Description with full game_box structure
            $replacement = $gameBoxStructure + $carouselSection + $getGameSection + @"
            <div class="public_box">
                <div class="box_three">
                    <h3>Description</h3>
                    <div class="dec">
$descriptionContent                    </div>
                </div>
            </div>
"@
            
            $content = $content -replace '(?s)<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>\s*<div class="dec">.*?</div>\s*</div>\s*</div>', $replacement
            
            Write-Host "  Restored game_box structure" -ForegroundColor Green
            $fixed++
        }
        
        # Ensure horizontal ad is present
        if ($content -notmatch 'First Display Ad - Horizontal \(468x50\)') {
            $navPattern = '(<p class="navigation">[^<]*<a[^>]*>Home</a>[^<]*&gt;&gt;[^<]*<span>[^<]*</span></p>)'
            if ($content -match $navPattern) {
                $content = $content -replace $navPattern, "`$1`n$firstHorizontalAd"
            }
        }
        
        # Save if changed
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
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow
Write-Host "  Errors: $errors" -ForegroundColor Red

