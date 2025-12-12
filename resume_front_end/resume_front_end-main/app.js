// Application data - will be loaded from Lambda via API Gateway
let mapData = [];
let globalMap = null;
let visitorCount = 0;

// API Configuration - Your API Gateway URL
const API_BASE_URL = 'https://d4dsm85lbi.execute-api.eu-west-2.amazonaws.com';

// reCAPTCHA Configuration - Replace with your actual site key
const RECAPTCHA_SITE_KEY = '6Lfv-xssAAAAANz9KbKMjYiSz2kduxNgpz6C0wfW';

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', async function() {
    initializeNavigation();
    
    // Make single API call to track visit and get all data
    await trackVisitAndLoadData();
    
    // Initialize components with the loaded data
    initializeMap();
    initializeLocationList();
    initializeScrollSpy();
});

// Navigation functionality
function initializeNavigation() {
    const navToggle = document.getElementById('nav-toggle');
    const navMenu = document.getElementById('nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');

    // Mobile menu toggle
    navToggle.addEventListener('click', function() {
        navToggle.classList.toggle('active');
        navMenu.classList.toggle('active');
    });

    // Close mobile menu when clicking on a nav link
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Remove active class from mobile menu
            navToggle.classList.remove('active');
            navMenu.classList.remove('active');
            
            // Get target section
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                // Smooth scroll to section
                targetSection.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Close mobile menu when clicking outside
    document.addEventListener('click', function(e) {
        if (!navToggle.contains(e.target) && !navMenu.contains(e.target)) {
            navToggle.classList.remove('active');
            navMenu.classList.remove('active');
        }
    });
}

// Single API call to track visit and load all data
async function trackVisitAndLoadData() {
    const counterElement = document.getElementById('visitor-count');

    try {
        // Add loading class to counter
        if (counterElement) {
            counterElement.classList.add('loading');
            counterElement.textContent = 'loading...';
        }

        console.log('Making API call to track visit and load data...');

        // Get reCAPTCHA token first
        let recaptchaToken = null;
        try {
            console.log('Getting reCAPTCHA token...');
            recaptchaToken = await new Promise((resolve, reject) => {
                grecaptcha.ready(function() {
                    grecaptcha.execute(RECAPTCHA_SITE_KEY, {action: 'visit'})
                        .then(function(token) {
                            console.log('reCAPTCHA token obtained');
                            resolve(token);
                        })
                        .catch(function(error) {
                            console.log('reCAPTCHA failed:', error);
                            reject(error);
                        });
                });
            });
        } catch (error) {
            console.log('Failed to get reCAPTCHA token:', error.message);
            // Continue without token - Lambda will handle missing token
            recaptchaToken = null;
        }

        // Get user's IP address
        let userIP = null;
        try {
            console.log('Fetching user IP address...');
            const ipResponse = await fetch('https://api.ipify.org?format=json');
            if (ipResponse.ok) {
                const ipData = await ipResponse.json();
                userIP = ipData.ip;
                console.log('User IP obtained:', userIP);
            }
        } catch (error) {
            console.log('Failed to get IP address:', error.message);
            // Fallback: let Lambda handle IP detection
            userIP = null;
        }

        // No GPS location collection - using IP-based location only

        // Prepare request payload with reCAPTCHA token
        const requestPayload = {
            action: 'visit',
            ip: userIP, // Send the IP address directly
            recaptchaToken: recaptchaToken, // Include reCAPTCHA token
            info: {
                userAgent: navigator.userAgent,
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                language: navigator.language,
                screenResolution: `${screen.width}x${screen.height}`,
                timestamp: new Date().toISOString()
            }
        };

        // Single API call to Lambda via API Gateway
        // The Lambda function will extract the real IP address from API Gateway headers
        const response = await fetch(`${API_BASE_URL}/visit`, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestPayload)
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        
        // Extract data from the response
        visitorCount = data.count || 0;
        mapData = data.locations || [];
        
        console.log('Data loaded successfully:');
        console.log('- Total visits:', visitorCount);
        console.log('- Current visit location:', data.current_visit?.location);
        console.log('- Location data points:', mapData.length);
        
        // Update visitor counter with animation
        if (counterElement) {
            setTimeout(() => {
                counterElement.textContent = visitorCount;
                counterElement.classList.remove('loading');
            }, 800);
        }
        
        // Log current visit info if available
        if (data.current_visit) {
            console.log('Current visit from:', data.current_visit.location, 
                       'at coordinates:', data.current_visit.coordinates);
        }
        
    } catch (error) {
        console.error('Lambda API call failed:', error);
        console.log('Using fallback data due to API error');
        
        // Fallback to default data if Lambda is not available
        visitorCount = 1031;
        mapData = [
            {"info": "London, United Kingdom", "lat": 51.5074, "lng": -0.1278, "views": 45},
            {"info": "New York, United States", "lat": 40.7128, "lng": -74.0060, "views": 32},
            {"info": "Toronto, Canada", "lat": 43.6532, "lng": -79.3832, "views": 28},
            {"info": "Sydney, Australia", "lat": -33.8688, "lng": 151.2093, "views": 19},
            {"info": "Berlin, Germany", "lat": 52.5200, "lng": 13.4050, "views": 15},
            {"info": "Amsterdam, Netherlands", "lat": 52.3676, "lng": 4.9041, "views": 12},
            {"info": "Paris, France", "lat": 48.8566, "lng": 2.3522, "views": 11}
        ];
        
        // Update counter with fallback data
        if (counterElement) {
            setTimeout(() => {
                counterElement.textContent = visitorCount;
                counterElement.classList.remove('loading');
            }, 800);
        }
    }
}
function initializeScrollSpy() {
    const sections = document.querySelectorAll('section[id], #home');
    const navLinks = document.querySelectorAll('.nav-link');
    
    const observerOptions = {
        root: null,
        rootMargin: '-20% 0px -60% 0px',
        threshold: 0
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const currentId = entry.target.getAttribute('id');
                
                // Remove active class from all nav links
                navLinks.forEach(link => {
                    link.classList.remove('active');
                });
                
                // Add active class to current nav link
                const currentNavLink = document.querySelector(`.nav-link[href="#${currentId}"]`);
                if (currentNavLink) {
                    currentNavLink.classList.add('active');
                }
            }
        });
    }, observerOptions);

    sections.forEach(section => {
        observer.observe(section);
    });
}

// Visitor counter is now handled in trackVisitAndLoadData() function

// Map initialization and functionality
function initializeMap() {
    try {
        // Initialize the map
        globalMap = L.map('map', {
            center: [40.0, 0.0], // Center on world view
            zoom: 2,
            zoomControl: true,
            scrollWheelZoom: true
        });

        // Add tile layer
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 18
        }).addTo(globalMap);

        // Store markers for later reference
        const markers = [];

        // Add markers for each location
        mapData.forEach(location => {
            // Create custom icon for markers
            const customIcon = L.divIcon({
                className: 'custom-marker',
                html: `<div style="background-color: #218085; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); cursor: pointer;">📍</div>`,
                iconSize: [28, 28],
                iconAnchor: [14, 14],
                popupAnchor: [0, -14]
            });

            const marker = L.marker([location.lat, location.lng], {
                icon: customIcon
            }).addTo(globalMap);

            // Create popup content with better styling
            const popupContent = `
                <div style="font-family: var(--font-family-base); min-width: 120px;">
                    <div class="popup-location" style="font-weight: bold; color: #218085; margin-bottom: 4px; font-size: 14px;">${location.info}</div>
                    <div class="popup-views" style="color: #626c7c; font-size: 12px;">${location.views} page views</div>
                </div>
            `;

            // Bind popup to marker
            marker.bindPopup(popupContent, {
                closeButton: true,
                autoClose: true,
                closeOnEscapeKey: true,
                className: 'custom-popup',
                offset: [0, -10]
            });

            // Add click event to open popup
            marker.on('click', function(e) {
                this.openPopup();
            });

            // Add hover events for better UX
            marker.on('mouseover', function(e) {
                this.openPopup();
            });

            // Close popup after delay on mouseout
            marker.on('mouseout', function(e) {
                const popup = this;
                setTimeout(() => {
                    popup.closePopup();
                }, 1500);
            });

            // Store marker reference
            markers.push({ marker, location });
        });

        // Store markers globally for location list interaction
        globalMap.customMarkers = markers;

        // Fit map to show all markers with padding
        if (markers.length > 0) {
            const group = new L.featureGroup(markers.map(m => m.marker));
            globalMap.fitBounds(group.getBounds().pad(0.1));
        }

    } catch (error) {
        console.error('Error initializing map:', error);
        document.getElementById('map').innerHTML = '<div style="display: flex; align-items: center; justify-content: center; height: 100%; color: #626c7c; font-size: 14px;">Map could not be loaded</div>';
    }
}

// Initialize location list
function initializeLocationList() {
    const locationListElement = document.getElementById('location-list');
    
    if (!locationListElement) {
        console.error('Location list element not found');
        return;
    }

    // Sort locations by views (descending)
    const sortedLocations = [...mapData].sort((a, b) => b.views - a.views);

    // Clear existing content
    locationListElement.innerHTML = '';

    // Create location items
    sortedLocations.forEach(location => {
        const locationItem = document.createElement('div');
        locationItem.className = 'location-item';
        
        locationItem.innerHTML = `
            <span class="location-name">${location.info}</span>
            <span class="location-views">${location.views} views</span>
        `;

        // Add click handler to center map on location
        locationItem.addEventListener('click', function() {
            centerMapOnLocation(location);
        });

        // Add hover effect
        locationItem.style.cursor = 'pointer';
        locationItem.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px)';
            this.style.boxShadow = '0 4px 8px rgba(0,0,0,0.1)';
            this.style.transition = 'all 0.2s ease';
        });

        locationItem.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = 'none';
            this.style.transition = 'all 0.2s ease';
        });

        locationListElement.appendChild(locationItem);
    });
}

// Function to center map on specific location
async function centerMapOnLocation(location) {
    if (globalMap && globalMap.customMarkers) {
        // Center map on location with zoom
        globalMap.setView([location.lat, location.lng], 6, {
            animate: true,
            duration: 1
        });
        
        // Find and open popup for this location
        globalMap.customMarkers.forEach(markerData => {
            const markerLocation = markerData.location;
            if (markerLocation.info === location.info) {
                // Delay popup opening to allow map animation to complete
                setTimeout(() => {
                    markerData.marker.openPopup();
                }, 500);
            }
        });
    }
}

// Add smooth scrolling for any anchor links (fallback)
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add intersection observer for fade-in animations on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const fadeInObserver = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe all sections for animation
document.addEventListener('DOMContentLoaded', function() {
    const sections = document.querySelectorAll('section');
    sections.forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(20px)';
        section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        fadeInObserver.observe(section);
    });
});

// Handle map resize on window resize
window.addEventListener('resize', function() {
    if (globalMap) {
        setTimeout(() => {
            globalMap.invalidateSize();
        }, 100);
    }
});

// Navbar scroll effect
let lastScrollTop = 0;
const navbar = document.getElementById('navbar');

window.addEventListener('scroll', function() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    
    // Add background blur when scrolled
    if (scrollTop > 20) {
        navbar.style.backdropFilter = 'blur(10px)';
        navbar.style.backgroundColor = 'rgba(var(--color-surface-rgb, 255, 255, 253), 0.95)';
    } else {
        navbar.style.backdropFilter = 'none';
        navbar.style.backgroundColor = 'var(--color-surface)';
    }
    
    lastScrollTop = scrollTop;
});

// Error handling for global errors
window.addEventListener('error', function(e) {
    console.error('Global error:', e.error);
});

// Handle unhandled promise rejections
window.addEventListener('unhandledrejection', function(e) {
    console.error('Unhandled promise rejection:', e.reason);
});

// Smooth scroll polyfill for older browsers
if (!('scrollBehavior' in document.documentElement.style)) {
    function smoothScrollTo(element) {
        const targetPosition = element.offsetTop - 80; // Account for fixed navbar
        const startPosition = window.pageYOffset;
        const distance = targetPosition - startPosition;
        const duration = 1000;
        let start = null;

        function animation(currentTime) {
            if (start === null) start = currentTime;
            const timeElapsed = currentTime - start;
            const run = easeInOutQuad(timeElapsed, startPosition, distance, duration);
            window.scrollTo(0, run);
            if (timeElapsed < duration) requestAnimationFrame(animation);
        }

        function easeInOutQuad(t, b, c, d) {
            t /= d / 2;
            if (t < 1) return c / 2 * t * t + b;
            t--;
            return -c / 2 * (t * (t - 2) - 1) + b;
        }

        requestAnimationFrame(animation);
    }

    // Override smooth scroll for nav links
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                smoothScrollTo(targetElement);
            }
        });
    });
}

/**
 * Toggles the visibility of a project details section.
 * It changes the CSS class from 'project-details-hidden' to 'project-details-visible' 
 * and scrolls the new content into view.
 * * @param {string} elementId - The ID of the HTML element to toggle (e.g., 'crc-details-section').
 */