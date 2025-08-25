// Modern UI Fix - Comprehensive JavaScript
document.addEventListener('DOMContentLoaded', function() {
    console.log('Modern UI Fix: Initializing...');
    
    // Force apply modern styles
    applyModernStyles();
    
    // Initialize all modern features
    initializeModernFeatures();
    
    // Fix theme toggle
    fixThemeToggle();
    
    // Initialize scroll reveal
    initializeScrollReveal();
    
    // Initialize navigation pills
    initializeNavigationPills();
    
    // Initialize animations
    initializeAnimations();
    
    console.log('Modern UI Fix: Complete!');
});

function applyModernStyles() {
    // Force apply Inter font
    document.body.style.fontFamily = "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
    
    // Ensure CSS variables are applied
    const root = document.documentElement;
    root.style.setProperty('--primary-color', '#0d6efd');
    root.style.setProperty('--bg-gradient', 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)');
    root.style.setProperty('--shadow', '0 0.5rem 1rem rgba(0, 0, 0, 0.15)');
    root.style.setProperty('--transition', 'all 0.3s ease');
    
    // Apply gradient to hero sections
    const heroSections = document.querySelectorAll('.hero-section, .bg-gradient-primary');
    heroSections.forEach(section => {
        section.style.background = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
        section.style.color = 'white';
    });
    
    // Apply glass card effects
    const glassCards = document.querySelectorAll('.glass-card');
    glassCards.forEach(card => {
        card.style.background = 'rgba(255, 255, 255, 0.1)';
        card.style.backdropFilter = 'blur(10px)';
        card.style.webkitBackdropFilter = 'blur(10px)';
        card.style.border = '1px solid rgba(255, 255, 255, 0.2)';
        card.style.borderRadius = '0.5rem';
        card.style.boxShadow = '0 0.5rem 1rem rgba(0, 0, 0, 0.15)';
        card.style.transition = 'all 0.3s ease';
    });
    
    // Apply enhanced card effects
    const enhancedCards = document.querySelectorAll('.enhanced-card');
    enhancedCards.forEach(card => {
        card.style.background = 'rgba(255, 255, 255, 0.95)';
        card.style.border = 'none';
        card.style.borderRadius = '0.5rem';
        card.style.boxShadow = '0 0.5rem 1rem rgba(0, 0, 0, 0.15)';
        card.style.transition = 'all 0.3s ease';
        card.style.overflow = 'hidden';
    });
}

function initializeModernFeatures() {
    // Add hover effects to cards
    const cards = document.querySelectorAll('.glass-card, .enhanced-card, .stats-card');
    cards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
            this.style.boxShadow = '0 1rem 2rem rgba(0, 0, 0, 0.25)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = '0 0.5rem 1rem rgba(0, 0, 0, 0.15)';
        });
    });
    
    // Add pulse animation to buttons
    const buttons = document.querySelectorAll('.btn, .nav-pill');
    buttons.forEach(button => {
        button.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px) scale(1.05)';
        });
        
        button.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });
}

function fixThemeToggle() {
    const themeToggle = document.getElementById('themeToggle');
    if (themeToggle) {
        // Apply modern styles to theme toggle
        themeToggle.style.position = 'fixed';
        themeToggle.style.top = '80px';
        themeToggle.style.right = '20px';
        themeToggle.style.zIndex = '1000';
        themeToggle.style.background = '#0d6efd';
        themeToggle.style.color = 'white';
        themeToggle.style.border = 'none';
        themeToggle.style.borderRadius = '50%';
        themeToggle.style.width = '50px';
        themeToggle.style.height = '50px';
        themeToggle.style.display = 'flex';
        themeToggle.style.alignItems = 'center';
        themeToggle.style.justifyContent = 'center';
        themeToggle.style.boxShadow = '0 0.5rem 1rem rgba(0, 0, 0, 0.15)';
        themeToggle.style.transition = 'all 0.3s ease';
        themeToggle.style.cursor = 'pointer';
        
        // Add hover effect
        themeToggle.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.1)';
            this.style.boxShadow = '0 1rem 2rem rgba(0, 0, 0, 0.25)';
        });
        
        themeToggle.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1)';
            this.style.boxShadow = '0 0.5rem 1rem rgba(0, 0, 0, 0.15)';
        });
        
        // Enhanced theme toggle functionality
        const body = document.body;
        const themeIcon = themeToggle.querySelector('i');
        
        // Load saved theme
        const savedTheme = localStorage.getItem('theme') || 'light';
        if (savedTheme === 'dark') {
            body.setAttribute('data-theme', 'dark');
            if (themeIcon) themeIcon.className = 'fas fa-sun';
            applyDarkTheme();
        }
        
        themeToggle.addEventListener('click', function() {
            const currentTheme = body.getAttribute('data-theme');
            
            // Add rotation animation
            this.style.transform = 'rotate(360deg) scale(1.1)';
            setTimeout(() => {
                this.style.transform = 'rotate(0deg) scale(1)';
            }, 400);
            
            if (currentTheme === 'dark') {
                body.removeAttribute('data-theme');
                if (themeIcon) themeIcon.className = 'fas fa-moon';
                localStorage.setItem('theme', 'light');
                applyLightTheme();
            } else {
                body.setAttribute('data-theme', 'dark');
                if (themeIcon) themeIcon.className = 'fas fa-sun';
                localStorage.setItem('theme', 'dark');
                applyDarkTheme();
            }
        });
    }
}

function applyDarkTheme() {
    document.body.style.backgroundColor = '#1a1a1a';
    document.body.style.color = '#ffffff';
    
    const heroSections = document.querySelectorAll('.hero-section, .bg-gradient-primary');
    heroSections.forEach(section => {
        section.style.background = 'linear-gradient(135deg, #2c3e50 0%, #34495e 100%)';
    });
    
    const enhancedCards = document.querySelectorAll('.enhanced-card');
    enhancedCards.forEach(card => {
        card.style.background = 'rgba(52, 58, 64, 0.95)';
        card.style.color = '#ffffff';
    });
}

function applyLightTheme() {
    document.body.style.backgroundColor = '';
    document.body.style.color = '';
    
    const heroSections = document.querySelectorAll('.hero-section, .bg-gradient-primary');
    heroSections.forEach(section => {
        section.style.background = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
    });
    
    const enhancedCards = document.querySelectorAll('.enhanced-card');
    enhancedCards.forEach(card => {
        card.style.background = 'rgba(255, 255, 255, 0.95)';
        card.style.color = '';
    });
}

function initializeScrollReveal() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('revealed');
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    const scrollElements = document.querySelectorAll('.scroll-reveal');
    scrollElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'all 0.8s ease-out';
        observer.observe(el);
    });
}

function initializeNavigationPills() {
    const navPills = document.querySelectorAll('.nav-pill');
    navPills.forEach(pill => {
        pill.style.display = 'flex';
        pill.style.alignItems = 'center';
        pill.style.gap = '0.5rem';
        pill.style.padding = '0.75rem 1.5rem';
        pill.style.background = 'rgba(255, 255, 255, 0.1)';
        pill.style.color = '#0d6efd';
        pill.style.textDecoration = 'none';
        pill.style.borderRadius = '25px';
        pill.style.border = '2px solid #0d6efd';
        pill.style.transition = 'all 0.3s ease';
        pill.style.fontWeight = '500';
        
        pill.addEventListener('mouseenter', function() {
            this.style.background = '#0d6efd';
            this.style.color = 'white';
            this.style.transform = 'translateY(-2px)';
            this.style.boxShadow = '0 0.5rem 1rem rgba(0, 0, 0, 0.15)';
        });
        
        pill.addEventListener('mouseleave', function() {
            if (!this.classList.contains('active')) {
                this.style.background = 'rgba(255, 255, 255, 0.1)';
                this.style.color = '#0d6efd';
            }
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = 'none';
        });
        
        pill.addEventListener('click', function(e) {
            // Remove active class from all pills
            navPills.forEach(p => {
                p.classList.remove('active');
                p.style.background = 'rgba(255, 255, 255, 0.1)';
                p.style.color = '#0d6efd';
            });
            
            // Add active class to clicked pill
            this.classList.add('active');
            this.style.background = '#0d6efd';
            this.style.color = 'white';
        });
    });
}

function initializeAnimations() {
    // Typing animation
    const typingElements = document.querySelectorAll('.typing-text');
    typingElements.forEach(element => {
        element.style.borderRight = '2px solid white';
        element.style.animation = 'typing 3s steps(20) infinite';
    });
    
    // Fade in animations
    const fadeElements = document.querySelectorAll('.animate-fade-in');
    fadeElements.forEach((element, index) => {
        element.style.opacity = '0';
        element.style.transform = 'translateY(30px)';
        element.style.transition = 'all 0.8s ease-out';
        
        setTimeout(() => {
            element.style.opacity = '1';
            element.style.transform = 'translateY(0)';
        }, index * 200);
    });
    
    // Pulse animations
    const pulseElements = document.querySelectorAll('.pulse-animation');
    pulseElements.forEach(element => {
        element.style.animation = 'pulse 2s infinite';
    });
}

// Mobile responsive adjustments
function applyMobileStyles() {
    if (window.innerWidth <= 768) {
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.style.top = '70px';
            themeToggle.style.right = '15px';
            themeToggle.style.width = '45px';
            themeToggle.style.height = '45px';
        }
        
        const navPillsContainer = document.querySelector('.nav-pills-container');
        if (navPillsContainer) {
            navPillsContainer.style.flexDirection = 'column';
            navPillsContainer.style.alignItems = 'center';
        }
        
        const navPills = document.querySelectorAll('.nav-pill');
        navPills.forEach(pill => {
            pill.style.width = '100%';
            pill.style.maxWidth = '200px';
            pill.style.justifyContent = 'center';
        });
    }
}

// Apply mobile styles on load and resize
window.addEventListener('load', applyMobileStyles);
window.addEventListener('resize', applyMobileStyles);

// Force refresh styles every 2 seconds for the first 10 seconds
let refreshCount = 0;
const refreshInterval = setInterval(() => {
    applyModernStyles();
    refreshCount++;
    if (refreshCount >= 5) {
        clearInterval(refreshInterval);
    }
}, 2000);
