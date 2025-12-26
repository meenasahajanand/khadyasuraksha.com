# Google AdSense Setup Instructions

## ✅ Completed Updates

### Main Pages Updated:
- ✅ index.html
- ✅ index-2.html  
- ✅ games.html
- ✅ hotgame.html
- ✅ newdategame.html

### Game Pages Updated (Examples):
- ✅ game/Minecraft.html
- ✅ game/Roblox.html

## 📋 Ad Units Applied

### 1. First Display Ad (After Header)
- **Ad Slot**: 1150075265 (2display_2512)
- **Size**: 300x600 (Desktop), 320x480 (Mobile)
- **Location**: Right after header, before main container
- **Status**: ✅ Applied to all main pages and example game pages

### 2. Second Display Ad (In Game Box)
- **Ad Slot**: 2463156936 (1dispaly_2512)
- **Size**: 320x480 (Horizontal)
- **Location**: Inside `.ad_box` div in game pages
- **Status**: ✅ Applied to example game pages

### 3. Inter Ad Units (3 Types)
- **Inter Ad 1** - Slot: 1685902515 (1inter_2512)
  - **Size**: 320x480 (Vertical)
  - **Location**: Before page footer/scripts
  - **Status**: ✅ Applied

- **Inter Ad 2** - Slot: 7523911922 (2inter_2512)
  - **Size**: 468x60 (Banner/Horizontal)
  - **Location**: Before page footer/scripts
  - **Status**: ✅ Applied

- **Inter Ad 3** - Slot: 6278278869 (3inter)
  - **Size**: 480x320 (Horizontal)
  - **Location**: Before page footer/scripts
  - **Status**: ✅ Applied

## 🚀 How to Update Remaining Game Pages

### Option 1: Use PowerShell Script (Recommended for Windows)

1. Open PowerShell in the project root directory
2. Run the script:
   ```powershell
   .\update-all-ads.ps1
   ```

This will automatically update all 220 game HTML files with:
- AdSense script in `<head>`
- First display ad after header
- Second display ad in ad_box

### Option 2: Manual Update Pattern

For each game page, add:

#### 1. In `<head>` section (after favicon link):
```html
<!-- Google AdSense -->
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7354377815781712"
 crossorigin="anonymous"></script>
```

#### 2. After header, before main container:
```html
<!-- First Display Ad - After Header -->
<div class="ads-container vertical" style="max-width: 300px; margin: 20px auto;">
    <div class="ad-label">Advertisement</div>
    <!-- 2display_2512 - 300x600 Desktop, 320x480 Mobile -->
    <ins class="adsbygoogle"
         style="display:block"
         data-ad-client="ca-pub-7354377815781712"
         data-ad-slot="1150075265"
         data-ad-format="auto"
         data-full-width-responsive="true"></ins>
    <script>
         (adsbygoogle = window.adsbygoogle || []).push({});
    </script>
</div>
```

#### 3. Replace existing ad_box content:
```html
<div class="ad_box">
    <div class="ad">
        <div style="width: 100%; max-width: 480px; margin: 0 auto;">
            <!-- 1dispaly_2512 - Second Display Ad Horizontal 320x480 -->
            <ins class="adsbygoogle"
                 style="display:block; width: 100%; max-width: 480px; height: 320px;"
                 data-ad-client="ca-pub-7354377815781712"
                 data-ad-slot="2463156936"
                 data-ad-format="auto"
                 data-full-width-responsive="true"></ins>
            <script>
                 (adsbygoogle = window.adsbygoogle || []).push({});
            </script>
        </div>
        <p>Advertisement</p>
    </div>
</div>
```

## 📱 Responsive Design

All ads are fully responsive:
- **Desktop (>768px)**: 300x600 vertical ad
- **Tablet (≤768px)**: 320x480 vertical ad
- **Mobile (≤480px)**: Auto-responsive sizing

CSS styles are already added in `css/main.css` for proper responsive behavior.

## ⚠️ Important Notes

1. **AdSense Approval**: Make sure your AdSense account is approved before ads will show
2. **Testing**: Use AdSense test ads to verify placement
3. **Policy Compliance**: Ensure ads don't interfere with content navigation
4. **Performance**: Ads load asynchronously to not block page rendering

## 🔍 Verification Checklist

- [ ] AdSense script added to all pages
- [ ] First display ad appears after header
- [ ] Second display ad appears in game_box
- [ ] Ads are responsive on mobile devices
- [ ] No console errors related to ads
- [ ] Ads don't overlap content

## 📞 Support

If you encounter any issues:
1. Check browser console for errors
2. Verify AdSense account status
3. Ensure ad slots are correctly configured in AdSense dashboard
4. Test on different devices and screen sizes

