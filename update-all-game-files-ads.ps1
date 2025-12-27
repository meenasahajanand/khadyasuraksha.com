# PowerShell Script to Update All Game Pages with Correct AdSense Ads Setup
# Based on Five_Nights_at_Freddy_s_2.html structure

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
        $originalContent = $content
        
        # Skip if already correctly updated (check for new format with Advertisement labels)
        if ($content -match 'First Display Ad - Horizontal \(468x50\)' -and 
            $content -match '<p style="text-align: center; margin-bottom: 10px; font-size: 12px; color: #999;">Advertisement</p>' -and
            $content -match 'Second Display Ad - Vertical \(300x600\)' -and
            $content -match 'font-weight: 700;">Advertisement</p>' -and
            $content -notmatch 'Second Vertical Ad \(300x600\)') {
            Write-Host "  Already correctly updated, skipping..." -ForegroundColor Yellow
            $skipped++
            continue
        }
        
        # 1. Add/Update AdSense script in head if not present
        if ($content -notmatch 'pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js') {
            $content = $content -replace '(?i)(<link rel="shortcut icon"[^>]*>)', "`$1`n$adSenseScript"
            Write-Host "  Added AdSense script" -ForegroundColor Green
        }
        
        # 2. Remove old ad before main container
        $content = $content -replace '(?s)<!-- First Display Ad - After Header -->.*?</div>\s*</div>\s*<div class="main container">', '<div class="main container">'
        $content = $content -replace '(?s)<div class="ads-container vertical"[^>]*>.*?</div>\s*</div>\s*<div class="main container">', '<div class="main container">'
        
        # 3. Update First Horizontal Ad after navigation (468x60 to 468x50, add Advertisement label)
        # Remove old horizontal ad (468x60)
        $content = $content -replace '(?s)<!-- First Display Ad - Horizontal \(468x60\) -->.*?</div>\s*</div>\s*</div>\s*<div class="public_box">', '<div class="public_box">'
        
        # Add/Update new horizontal ad (468x50) with Advertisement label
        $navPattern = '(<p class="navigation">[^<]*<a[^>]*>Home</a>[^<]*&gt;&gt;[^<]*<span>[^<]*</span></p>)'
        if ($content -match $navPattern) {
            if ($content -notmatch 'First Display Ad - Horizontal \(468x50\)') {
                $content = $content -replace $navPattern, "`$1`n$firstHorizontalAd"
                Write-Host "  Added/Updated first horizontal ad (468x50)" -ForegroundColor Green
            } else {
                # Update existing 468x50 ad to add Advertisement label if missing
                if ($content -notmatch '<p style="text-align: center; margin-bottom: 10px; font-size: 12px; color: #999;">Advertisement</p>.*?First Display Ad - Horizontal \(468x50\)') {
                    $adLabel = '<p style="text-align: center; margin-bottom: 10px; font-size: 12px; color: #999;">Advertisement</p>'
                    $content = $content -replace '(?s)(<!-- First Display Ad - Horizontal \(468x50\) -->\s*<div class="s_box"[^>]*>\s*<div style="text-align: center; padding: 10px;">)', "`$1`n                    $adLabel"
                    Write-Host "  Added Advertisement label to first ad" -ForegroundColor Green
                }
                # Update height from 60px to 50px if still 60px
                $content = $content -replace 'style="display:inline-block; width: 468px; height: 60px;"', 'style="display:inline-block; width: 468px; height: 50px;"'
            }
        }
        
        # 4. Update ad_box with vertical ad (300x600) with Advertisement label
        $adBoxPattern = '(?s)(<div class="ad_box">\s*<div class="ad">.*?</div>\s*</div>\s*</div>)'
        if ($content -match $adBoxPattern) {
            # Check if it already has the correct format
            if ($content -match 'Second Display Ad - Vertical \(300x600\)' -and $content -match 'font-weight: 700;">Advertisement</p>') {
                Write-Host "  ad_box already correct" -ForegroundColor Yellow
            } else {
                $content = $content -replace $adBoxPattern, $verticalAdInAdBox
                Write-Host "  Updated ad_box with vertical ad (300x600)" -ForegroundColor Green
            }
        } else {
            # If ad_box doesn't exist, add it before closing game_box
            $gameBoxClosePattern = '(?s)(</div>\s*</div>\s*</div>\s*</div>\s*<!--.*?-->|</div>\s*</div>\s*</div>\s*</div>\s*<div class="public_box">)'
            if ($content -match $gameBoxClosePattern) {
                $content = $content -replace $gameBoxClosePattern, "$verticalAdInAdBox`n`$1"
                Write-Host "  Added ad_box with vertical ad" -ForegroundColor Green
            }
        }
        
        # 5. Remove second vertical ad after carousel (if exists)
        $content = $content -replace '(?s)<!-- Second Vertical Ad \(300x600\) -->.*?</div>\s*</div>\s*</div>\s*<div class="public_box">\s*<div class="box_three">', '<div class="public_box">' + [Environment]::NewLine + '                <div class="box_three">'
        
        # 6. Remove old ads (970x90, 800x300, etc.)
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 970px;height: 90px;">.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<div class="s_box">\s*<div class="ad">\s*<div style="width: 800px;height: 300px;">.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<!-- /22239042571/civilitythegame-lxl/civilitythegame-970x90.*?</div>\s*</div>\s*</div>', ''
        $content = $content -replace '(?s)<!-- /22239042571/civilitythegame-lxl/civilitythegame-800x300.*?</div>\s*</div>\s*</div>', ''
        
        # 7. Remove old googletag ads
        $content = $content -replace '(?s)<div id=''div-gpt-ad-[^>]*>.*?</div>\s*</div>', ''
        
        # Only save if content changed
        if ($content -ne $originalContent) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            $updated++
            Write-Host "  Updated successfully!" -ForegroundColor Green
        } else {
            Write-Host "  No changes needed" -ForegroundColor Yellow
            $skipped++
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
Write-Host "  Updated: $updated" -ForegroundColor Green
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All game files have been updated with:" -ForegroundColor Cyan
Write-Host "  - First Horizontal Ad (468x50) with Advertisement label" -ForegroundColor Green
Write-Host "  - Second Vertical Ad (300x600) in ad_box with Advertisement label" -ForegroundColor Green
Write-Host "  - Old ads removed" -ForegroundColor Green

