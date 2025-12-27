# PowerShell Script to Update All Game Pages with AdSense Ads
# Same setup as Five_Nights_at_Freddy_s_2.html

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
$updated = 0
$skipped = 0
$errors = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    Write-Host "[$count/$($gameFiles.Count)] Processing: $($file.Name)" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        # Skip if already updated correctly
        if ($content -match 'First Display Ad - Horizontal \(468x50\).*Advertisement.*468px.*50px' -and 
            $content -match 'Second Display Ad - Vertical \(300x600\).*Advertisement.*300px.*600px') {
            Write-Host "  Already updated correctly, skipping..." -ForegroundColor Yellow
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
            # Remove old horizontal ad if exists
            $content = $content -replace '(?s)<!-- First Display Ad - Horizontal.*?</div>\s*</div>\s*</div>\s*<div class="public_box">', '<div class="public_box">'
            
            # Add new horizontal ad (468x50) with Advertisement label
            if ($content -notmatch 'First Display Ad - Horizontal \(468x50\).*Advertisement.*468px.*50px') {
                $content = $content -replace $navPattern, "`$1`n$firstHorizontalAd"
                Write-Host "  Added/Updated first horizontal ad" -ForegroundColor Green
            }
        }
        
        # 4. Update ad_box with vertical ad (300x600) with Advertisement label
        $adBoxPattern = '(?s)(<div class="ad_box">\s*<div class="ad">.*?</div>\s*</div>\s*</div>)'
        if ($content -match $adBoxPattern) {
            $content = $content -replace $adBoxPattern, $verticalAdInAdBox
            Write-Host "  Updated ad_box with vertical ad" -ForegroundColor Green
        } else {
            # If ad_box doesn't exist, add it before closing game_box
            $gameBoxClosePattern = '(?s)(</div>\s*</div>\s*</div>\s*<div class="public_box">)'
            if ($content -match $gameBoxClosePattern) {
                $content = $content -replace $gameBoxClosePattern, "$verticalAdInAdBox`n`$1"
                Write-Host "  Added ad_box with vertical ad" -ForegroundColor Green
            }
        }
        
        # 5. Remove old ads
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 970px;height: 90px;">.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 800px;height: 300px;">.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<!-- Second Vertical Ad \(300x600\) -->.*?</div>\s*</div>\s*</div>\s*<div class="public_box">', '<div class="public_box">'
        
        # Save the file
        $content | Set-Content $filePath -Encoding UTF8 -NoNewline
        $updated++
        Write-Host "  Updated successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files: $count" -ForegroundColor White
Write-Host "  Updated: $updated" -ForegroundColor Green
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
