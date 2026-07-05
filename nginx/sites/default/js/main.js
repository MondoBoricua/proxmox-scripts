// JavaScript para Nginx Server - Sitio de Ejemplo
// Desarrollado con ❤️ para la comunidad de Proxmox
// Hecho en 🇵🇷 Puerto Rico con mucho ☕ café

// Esperar a que el DOM esté completamente cargado
document.addEventListener('DOMContentLoaded', function() {
    
    // Función para mostrar información del servidor
    function displayServerInfo() {
        // Obtener IP del cliente (aproximada)
        const userIP = 'Tu IP'; // En un servidor real se obtendría del backend
        
        // Mostrar fecha y hora actual
        const now = new Date();
        const timeString = now.toLocaleString('es-ES', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
        
        // Crear elemento de información de conexión
        const connectionInfo = document.createElement('div');
        connectionInfo.className = 'connection-info';
        connectionInfo.innerHTML = `
            <div style="background: rgba(255, 255, 255, 0.95); padding: 1.5rem; border-radius: 15px; margin: 2rem 0; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);">
                <h3 style="color: #667eea; margin-bottom: 1rem; text-align: center;">🌐 Información de Conexión</h3>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; text-align: center;">
                    <div>
                        <strong>Fecha y Hora:</strong><br>
                        <span style="font-family: monospace; color: #666;">${timeString}</span>
                    </div>
                    <div>
                        <strong>Navegador:</strong><br>
                        <span style="font-family: monospace; color: #666;">${navigator.userAgent.split(' ')[0]}</span>
                    </div>
                    <div>
                        <strong>Plataforma:</strong><br>
                        <span style="font-family: monospace; color: #666;">${navigator.platform}</span>
                    </div>
                </div>
            </div>
        `;
        
        // Insertar después del status badge
        const statusBadge = document.querySelector('.status-badge');
        statusBadge.parentNode.insertBefore(connectionInfo, statusBadge.nextSibling);
    }
    
    // Función para animar las tarjetas cuando entran en vista
    function animateCards() {
        const cards = document.querySelectorAll('.info-card, .feature-item, .command-item');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, {
            threshold: 0.1
        });
        
        cards.forEach(card => {
            card.style.opacity = '0';
            card.style.transform = 'translateY(20px)';
            card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            observer.observe(card);
        });
    }
    
    // Función para crear efecto de typing en el título
    function typewriterEffect() {
        const title = document.querySelector('.header h1');
        const text = title.textContent;
        title.textContent = '';
        title.style.borderRight = '2px solid white';
        
        let i = 0;
        const timer = setInterval(() => {
            title.textContent += text.charAt(i);
            i++;
            if (i > text.length) {
                clearInterval(timer);
                title.style.borderRight = 'none';
            }
        }, 100);
    }
    
    // Función para agregar interactividad a los comandos
    function addCommandInteractivity() {
        const commandItems = document.querySelectorAll('.command-item code');
        
        commandItems.forEach(command => {
            command.style.cursor = 'pointer';
            command.title = 'Click para copiar al portapapeles';
            
            command.addEventListener('click', function() {
                // Copiar al portapapeles
                navigator.clipboard.writeText(this.textContent).then(() => {
                    // Mostrar feedback visual
                    const originalBg = this.style.backgroundColor;
                    this.style.backgroundColor = '#48bb78';
                    this.style.color = 'white';
                    
                    setTimeout(() => {
                        this.style.backgroundColor = originalBg;
                        this.style.color = '#68d391';
                    }, 1000);
                    
                    // Mostrar tooltip
                    showTooltip(this, '¡Copiado!');
                }).catch(() => {
                    showTooltip(this, 'Error al copiar');
                });
            });
        });
    }
    
    // Función para mostrar tooltip
    function showTooltip(element, text) {
        const tooltip = document.createElement('div');
        tooltip.textContent = text;
        tooltip.style.cssText = `
            position: absolute;
            background: #2d3748;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            font-size: 0.8rem;
            z-index: 1000;
            pointer-events: none;
            opacity: 0;
            transition: opacity 0.3s ease;
        `;
        
        document.body.appendChild(tooltip);
        
        const rect = element.getBoundingClientRect();
        tooltip.style.left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2) + 'px';
        tooltip.style.top = rect.top - tooltip.offsetHeight - 10 + 'px';
        
        setTimeout(() => tooltip.style.opacity = '1', 10);
        
        setTimeout(() => {
            tooltip.style.opacity = '0';
            setTimeout(() => document.body.removeChild(tooltip), 300);
        }, 2000);
    }
    
    // Función para agregar contador de visitantes simulado
    function addVisitorCounter() {
        const visitors = Math.floor(Math.random() * 1000) + 100;
        const counter = document.createElement('div');
        counter.innerHTML = `
            <div style="background: rgba(255, 255, 255, 0.95); padding: 1rem; border-radius: 15px; margin: 1rem 0; text-align: center; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);">
                <span style="color: #667eea; font-weight: bold;">👥 Visitantes hoy: </span>
                <span style="color: #48bb78; font-weight: bold; font-family: monospace;">${visitors}</span>
            </div>
        `;
        
        const footer = document.querySelector('.footer');
        footer.parentNode.insertBefore(counter, footer);
    }
    
    // Función para crear efecto de partículas en el fondo
    function createParticles() {
        const particlesContainer = document.createElement('div');
        particlesContainer.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: -1;
        `;
        
        document.body.appendChild(particlesContainer);
        
        for (let i = 0; i < 20; i++) {
            const particle = document.createElement('div');
            particle.style.cssText = `
                position: absolute;
                width: 4px;
                height: 4px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                animation: float ${Math.random() * 3 + 2}s infinite ease-in-out;
                left: ${Math.random() * 100}%;
                top: ${Math.random() * 100}%;
                animation-delay: ${Math.random() * 2}s;
            `;
            
            particlesContainer.appendChild(particle);
        }
        
        // Agregar CSS para la animación de partículas
        const style = document.createElement('style');
        style.textContent = `
            @keyframes float {
                0%, 100% { transform: translateY(0px) rotate(0deg); opacity: 0.3; }
                50% { transform: translateY(-20px) rotate(180deg); opacity: 0.8; }
            }
        `;
        document.head.appendChild(style);
    }
    
    // Función para agregar scroll suave
    function addSmoothScroll() {
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
    }
    
    // Función para mostrar tiempo de carga
    function showLoadTime() {
        const loadTime = performance.now();
        const loadTimeElement = document.createElement('div');
        loadTimeElement.innerHTML = `
            <div style="position: fixed; bottom: 20px; right: 20px; background: rgba(0, 0, 0, 0.8); color: white; padding: 0.5rem 1rem; border-radius: 10px; font-size: 0.8rem; z-index: 1000;">
                ⚡ Cargado en ${Math.round(loadTime)}ms
            </div>
        `;
        
        document.body.appendChild(loadTimeElement);
        
        // Ocultar después de 5 segundos
        setTimeout(() => {
            loadTimeElement.style.opacity = '0';
            loadTimeElement.style.transition = 'opacity 0.5s ease';
            setTimeout(() => {
                if (loadTimeElement.parentNode) {
                    loadTimeElement.parentNode.removeChild(loadTimeElement);
                }
            }, 500);
        }, 5000);
    }
    
    // Función principal de inicialización
    function init() {
        console.log('🌐 Nginx Server - Sitio de ejemplo cargado');
        console.log('Desarrollado con ❤️ para la comunidad de Proxmox');
        console.log('Hecho en 🇵🇷 Puerto Rico con mucho ☕ café');
        
        // Ejecutar todas las funciones
        displayServerInfo();
        animateCards();
        addCommandInteractivity();
        addVisitorCounter();
        createParticles();
        addSmoothScroll();
        showLoadTime();
        
        // Efecto typewriter solo en pantallas grandes
        if (window.innerWidth > 768) {
            setTimeout(typewriterEffect, 500);
        }
        
        // Mensaje de bienvenida en consola
        setTimeout(() => {
            console.log('%c¡Bienvenido a tu servidor Nginx!', 'color: #667eea; font-size: 20px; font-weight: bold;');
            console.log('%cPara gestionar tu servidor, usa los comandos disponibles en la interfaz.', 'color: #48bb78;');
        }, 1000);
    }
    
    // Inicializar cuando el DOM esté listo
    init();
    
    // Agregar listener para cambios de tamaño de ventana
    window.addEventListener('resize', function() {
        // Reajustar elementos si es necesario
        const particles = document.querySelector('[style*="position: fixed"]');
        if (particles && window.innerWidth < 768) {
            particles.style.display = 'none';
        } else if (particles) {
            particles.style.display = 'block';
        }
    });
    
    // Agregar easter egg
    let konami = [];
    const konamiCode = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'KeyB', 'KeyA'];
    
    document.addEventListener('keydown', function(e) {
        konami.push(e.code);
        if (konami.length > konamiCode.length) {
            konami.shift();
        }
        
        if (konami.join(',') === konamiCode.join(',')) {
            // Easter egg activado
            const logo = document.querySelector('.logo');
            logo.style.animation = 'spin 2s linear infinite';
            
            const style = document.createElement('style');
            style.textContent = `
                @keyframes spin {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }
            `;
            document.head.appendChild(style);
            
            setTimeout(() => {
                logo.style.animation = 'bounce 2s infinite';
            }, 4000);
            
            console.log('🎉 ¡Easter egg activado! ¡Eres un verdadero ninja de nginx!');
        }
    });
}); 