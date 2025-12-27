# PowerShell Script to Restore All Game Pages to Correct Structure
# For box_three pages: Only horizontal ad after navigation, NO vertical ad
# For game_box pages: Horizontal ad + vertical ad in ad_box

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
        
        # 1. Ensure AdSense script in head
        if ($content -notmatch 'pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js') {
            $content = $content -replace '(?i)(<link rel="shortcut icon"[^>]*>)', "`$1`n    <!-- Google AdSense -->`n    <script async src=`"https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7354377815781712`"`n     crossorigin=`"anonymous`"></script>"
        }
        
        # 2. Fix first horizontal ad after navigation
        $navPattern = '(<p class="navigation">[^<]*<a[^>]*>Home</a>[^<]*&gt;&gt;[^<]*<span>[^<]*</span></p>)'
        if ($content -match $navPattern) {
            # Remove any existing first ad
            $content = $content -replace '(?s)<!-- First Display Ad - Horizontal.*?</div>\s*</div>\s*</div>\s*<div class="public_box">', '<div class="public_box">'
            $content = $content -replace '(?s)<div class="s_box"[^>]*>.*?Advertisement.*?468px.*?50px.*?</div>\s*</div>\s*</div>\s*<div class="public_box">', '<div class="public_box">'
            
            # Add correct horizontal ad if not present
            if ($content -notmatch 'First Display Ad - Horizontal \(468x50\).*Advertisement.*468px.*50px') {
                $content = $content -replace $navPattern, "`$1`n$firstHorizontalAd"
            }
        }
        
        if ($hasGameBox) {
            # File has game_box - ensure ad_box with vertical ad exists
            $adBoxPattern = '(?s)(<div class="ad_box">\s*<div class="ad">.*?</div>\s*</div>\s*</div>)'
            if ($content -match $adBoxPattern) {
                # Update existing ad_box
                if ($content -notmatch 'Second Display Ad - Vertical \(300x600\).*Advertisement.*300px.*600px') {
                    $content = $content -replace $adBoxPattern, $verticalAdInAdBox
                    Write-Host "  Updated ad_box with vertical ad" -ForegroundColor Green
                }
            } else {
                # Add ad_box before closing game_box
                $gameBoxClosePattern = '(?s)(</div>\s*</div>\s*</div>\s*<!--[^>]*-->|</div>\s*</div>\s*</div>\s*<div class="public_box">)'
                if ($content -match $gameBoxClosePattern) {
                    $content = $content -replace $gameBoxClosePattern, "$verticalAdInAdBox`n`$1"
                    Write-Host "  Added ad_box with vertical ad" -ForegroundColor Green
                }
            }
        } else {
            # File has box_three - remove any ad_box or vertical ads
            # Remove ad_box if it exists
            $content = $content -replace '(?s)<div class="ad_box">.*?</div>\s*</div>\s*</div>', ''
            # Remove any vertical ad containers
            $content = $content -replace '(?s)<!-- Second Display Ad - Vertical.*?</div>\s*</div>\s*</div>', ''
            $content = $content -replace '(?s)<div[^>]*>.*?300px.*?600px.*?Advertisement.*?</div>\s*</div>', ''
            Write-Host "  Removed vertical ads from box_three page" -ForegroundColor Green
        }
        
        # 3. Remove old/unwanted ads
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 970px;height: 90px;">.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 800px;height: 300px;">.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<!-- First Display Ad - After Header -->.*?</div>\s*</div>\s*<div class="main container">', '<div class="main container">'
        $content = $content -replace '(?s)<div class="ads-container vertical"[^>]*>.*?</div>\s*</div>\s*<div class="main container">', '<div class="main container">'
        
        # Save if changed
        if ($content -ne $originalContent) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            $fixed++
            Write-Host "  Fixed!" -ForegroundColor Green
        } else {
            Write-Host "  Already correct" -ForegroundColor Yellow
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

