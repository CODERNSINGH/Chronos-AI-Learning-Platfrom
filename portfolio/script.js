// ============================================
// CHRONOS PORTFOLIO - JAVASCRIPT
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    
    // --- 1. INTERSECTION OBSERVER FOR REVEALS ---
    const observerOptions = {
        threshold: 0.15,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                // Add stagger delay if specified
                if (entry.target.dataset.delay) {
                    entry.target.style.transitionDelay = `${entry.target.dataset.delay}ms`;
                }
                entry.target.classList.add('is-visible');
                // Optional: stop observing once revealed
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    document.querySelectorAll('[data-animate]').forEach(el => {
        observer.observe(el);
    });

    // --- 2. SCROLL LINKED EFFECTS ---
    const navbar = document.querySelector('.navbar');
    const heroDevice = document.querySelector('.hero-device-wrapper');
    const stickyBlocks = document.querySelectorAll('.sticky-block');
    const stickyImages = document.querySelectorAll('.sticky-img');

    window.addEventListener('scroll', () => {
        const scrollY = window.scrollY;

        // Navbar blur effect
        if (scrollY > 50) {
            navbar.style.background = 'rgba(0, 0, 0, 0.7)';
            navbar.style.borderBottom = '1px solid rgba(255, 255, 255, 0.1)';
        } else {
            navbar.style.background = 'transparent';
            navbar.style.borderBottom = '1px solid transparent';
        }

        // Hero Parallax & Scale
        if (heroDevice && scrollY < window.innerHeight) {
            // Scale down slightly as we scroll away
            const scale = Math.max(0.85, 1 - (scrollY / window.innerHeight) * 0.3);
            const translateY = scrollY * 0.4;
            heroDevice.style.transform = `scale(${scale}) translateY(${translateY}px)`;
            heroDevice.style.opacity = 1 - (scrollY / window.innerHeight) * 1.5;
        }

        // Sticky Section Image Swapping
        // Find which block is closest to the vertical center of the screen
        let activeIndex = 0;
        let minDistance = Infinity;
        const windowCenter = window.innerHeight / 2;

        stickyBlocks.forEach((block, index) => {
            const rect = block.getBoundingClientRect();
            // Calculate distance from block center to window center
            const blockCenter = rect.top + rect.height / 2;
            const distance = Math.abs(windowCenter - blockCenter);
            
            if (distance < minDistance) {
                minDistance = distance;
                activeIndex = index;
            }
        });

        // Update active states
        stickyBlocks.forEach((block, index) => {
            if (index === activeIndex) {
                block.classList.add('is-active');
            } else {
                block.classList.remove('is-active');
            }
        });

        stickyImages.forEach((img, index) => {
            if (index === activeIndex) {
                img.classList.add('is-active');
            } else {
                img.classList.remove('is-active');
            }
        });
    });

    // Trigger scroll once to set initial states
    window.dispatchEvent(new Event('scroll'));

    // --- 3. FORM HANDLING ---
    const contactForm = document.getElementById('contactForm');
    if (contactForm) {
        contactForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const btn = contactForm.querySelector('button');
            const originalText = btn.textContent;
            
            btn.textContent = 'Sending...';
            btn.style.opacity = '0.7';
            
            // Simulate API call
            setTimeout(() => {
                btn.textContent = 'Message Sent ✓';
                btn.style.background = '#34C759'; // Apple success green
                btn.style.color = '#fff';
                btn.style.opacity = '1';
                
                setTimeout(() => {
                    contactForm.reset();
                    btn.textContent = originalText;
                    btn.style.background = '';
                    btn.style.color = '';
                }, 3000);
            }, 1000);
        });
    }

    // --- 4. LIGHTBOX FOR GALLERY ---
    const galleryItems = document.querySelectorAll('.gallery-item img');
    galleryItems.forEach(img => {
        img.addEventListener('click', () => {
            createLightbox(img.src, img.alt);
        });
        img.style.cursor = 'pointer';
    });

});

function createLightbox(src, alt) {
    const lightbox = document.createElement('div');
    lightbox.style.cssText = `
        position: fixed; top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(0, 0, 0, 0.9);
        backdrop-filter: blur(10px);
        display: flex; align-items: center; justify-content: center;
        z-index: 10000; cursor: pointer;
        opacity: 0; transition: opacity 0.3s ease;
    `;

    const img = document.createElement('img');
    img.src = src;
    img.style.cssText = `
        max-width: 90vw; max-height: 90vh;
        border-radius: 20px;
        box-shadow: 0 20px 60px rgba(0,0,0,0.5);
        transform: scale(0.95); transition: transform 0.3s cubic-bezier(0.25, 1, 0.5, 1);
    `;

    lightbox.appendChild(img);
    document.body.appendChild(lightbox);

    // Trigger reflow for animation
    requestAnimationFrame(() => {
        lightbox.style.opacity = '1';
        img.style.transform = 'scale(1)';
    });

    lightbox.addEventListener('click', () => {
        lightbox.style.opacity = '0';
        img.style.transform = 'scale(0.95)';
        setTimeout(() => lightbox.remove(), 300);
    });
}
