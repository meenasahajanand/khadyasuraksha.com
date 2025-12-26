// Mobile Menu Toggle Functionality
(function() {
    'use strict';
    
    // Create mobile menu toggle button
    function initMobileMenu() {
        // Check if we're on mobile
        if (window.innerWidth > 768) {
            return;
        }
        
        // Check if toggle button already exists
        if (document.querySelector('.mobile-menu-toggle')) {
            return;
        }
        
        // Create toggle button
        const toggleBtn = document.createElement('div');
        toggleBtn.className = 'mobile-menu-toggle';
        toggleBtn.innerHTML = '<span></span><span></span><span></span>';
        document.body.appendChild(toggleBtn);
        
        // Create overlay
        const overlay = document.createElement('div');
        overlay.className = 'mobile-overlay';
        document.body.appendChild(overlay);
        
        const aside = document.querySelector('.aside');
        
        // Toggle menu function
        function toggleMenu() {
            toggleBtn.classList.toggle('active');
            if (aside) {
                aside.classList.toggle('active');
            }
            overlay.classList.toggle('active');
            document.body.classList.toggle('menu-open');
        }
        
        // Event listeners
        toggleBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            toggleMenu();
        });
        
        overlay.addEventListener('click', function() {
            toggleMenu();
        });
        
        // Close menu when clicking on a link
        const menuLinks = document.querySelectorAll('.aside a');
        menuLinks.forEach(function(link) {
            link.addEventListener('click', function() {
                if (window.innerWidth <= 768) {
                    toggleMenu();
                }
            });
        });
        
        // Close menu on window resize
        let resizeTimer;
        window.addEventListener('resize', function() {
            clearTimeout(resizeTimer);
            resizeTimer = setTimeout(function() {
                if (window.innerWidth > 768) {
                    toggleBtn.classList.remove('active');
                    if (aside) {
                        aside.classList.remove('active');
                    }
                    overlay.classList.remove('active');
                    document.body.classList.remove('menu-open');
                }
            }, 250);
        });
    }
    
    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initMobileMenu);
    } else {
        initMobileMenu();
    }
    
    // Re-initialize on window load
    window.addEventListener('load', function() {
        initMobileMenu();
    });
})();

