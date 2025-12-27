# PowerShell Script to Update All Game Pages with AdSense Ads
# This script applies: 1 Horizontal Ad + 2 Vertical Ads to all game pages

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$adSenseScript = @"
    <!-- Google AdSense -->
    <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7354377815781712"
     crossorigin="anonymous"></script>
"@

$firstHorizontalAd = @"
            <!-- First Display Ad - Horizontal (468x50) -->
            <div class="s_box" style="margin-bottom: 15px;">
                <div style="text-align: center; padding: 10px;">
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
                            <p>Advertisement</p>
                        </div>
                    </div>
"@

$secondVerticalAd = @"
            <!-- Second Vertical Ad (300x600) -->
            <div class="s_box" style="margin-bottom: 15px;">
                <div style="text-align: center; padding: 10px;">
                    <div style="width: 100%; max-width: 300px; margin: 0 auto;">
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
                    <p style="text-align: center; margin-top: 10px; font-size: 12px; color: #999;">Advertisement</p>
                </div>
            </div>
"@

$count = 0
$updated = 0
$skipped = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    Write-Host "[$count/$($gameFiles.Count)] Processing: $($file.Name)" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        # Skip if already updated (check for new ad format)
        if ($content -match 'First Display Ad - Horizontal \(468x50\)' -and 
            $content -match 'Second Display Ad - Vertical \(300x600\)' -and
            $content -match 'Second Vertical Ad \(300x600\)') {
            Write-Host "  Already updated, skipping..." -ForegroundColor Yellow
            $skipped++
            continue
        }
        
        # 1. Add/Update AdSense script in head
        if ($content -notmatch 'pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js') {
            $content = $content -replace '(?i)(<link rel="shortcut icon"[^>]*>)', "`$1`n$adSenseScript"
            Write-Host "  Added AdSense script" -ForegroundColor Green
        }
        
        # 2. Remove old ad before main container
        $content = $content -replace '(?s)<!-- First Display Ad - After Header -->.*?</div>\s*</div>\s*<div class="main container">', '<div class="main container">'
        $content = $content -replace '(?s)<div class="ads-container vertical"[^>]*>.*?</div>\s*</div>\s*<div class="main container">', '<div class="main container">'
        
        # 3. Add/Update First Horizontal Ad after navigation
        $navPattern = '(<p class="navigation">[^<]*<a[^>]*>Home</a>[^<]*&gt;&gt;[^<]*<span>[^<]*</span></p>)'
        if ($content -match $navPattern) {
            # Remove old horizontal ad if exists (468x60)
            $content = $content -replace '(?s)<!-- First Display Ad - Horizontal \(468x60\) -->.*?</div>\s*</div>\s*</div>\s*<div class="public_box">', '<div class="public_box">'
            
            # Add new horizontal ad (468x50)
            if ($content -notmatch 'First Display Ad - Horizontal \(468x50\)') {
                $content = $content -replace $navPattern, "`$1`n$firstHorizontalAd"
                Write-Host "  Added first horizontal ad" -ForegroundColor Green
            }
        }
        
        # 4. Update ad_box with vertical ad (300x600)
        $adBoxPattern = '(?s)(<div class="ad_box">\s*<div class="ad">.*?</div>\s*</div>\s*</div>)'
        if ($content -match $adBoxPattern) {
            $content = $content -replace $adBoxPattern, $verticalAdInAdBox
            Write-Host "  Updated ad_box with vertical ad" -ForegroundColor Green
        } else {
            # If ad_box doesn't exist, add it before closing game_box
            $gameBoxClosePattern = '(?s)(</div>\s*</div>\s*</div>\s*</div>\s*<!--轮播-->|</div>\s*</div>\s*</div>\s*</div>\s*<div class="public_box">)'
            if ($content -match $gameBoxClosePattern) {
                $content = $content -replace $gameBoxClosePattern, "$verticalAdInAdBox`n`$1"
                Write-Host "  Added ad_box with vertical ad" -ForegroundColor Green
            }
        }
        
        # 5. Add second vertical ad after carousel (before "Get the Game" or old 970x90 ad)
        # Remove old 970x90 ad
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 970px;height: 90px;">.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 800px;height: 300px;">.*?</div>\s*</div>\s*</div>', ''
        
        # Add second vertical ad before "Get the Game" section
        if ($content -match 'Get the Game' -and $content -notmatch 'Second Vertical Ad \(300x600\)') {
            $content = $content -replace '(<div class="public_box">\s*<div class="box_three">\s*<h3>Get the Game</h3>)', "$secondVerticalAd`n`$1"
            Write-Host "  Added second vertical ad" -ForegroundColor Green
        } elseif ($content -match '<div class="public_box">\s*<div class="box_three">' -and $content -notmatch 'Second Vertical Ad \(300x600\)') {
            $content = $content -replace '(<div class="public_box">\s*<div class="box_three">)', "$secondVerticalAd`n`$1"
            Write-Host "  Added second vertical ad" -ForegroundColor Green
        }
        
        # Save the file
        $content | Set-Content $filePath -Encoding UTF8 -NoNewline
        $updated++
        Write-Host "  ✓ Updated successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files: $count" -ForegroundColor White
Write-Host "  Updated: $updated" -ForegroundColor Green
Write-Host "  Skipped (already updated): $skipped" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

