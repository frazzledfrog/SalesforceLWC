// Utility module Confetti for celebratory animations
// Confetti utility for LWC (vanilla JS, no dependencies)
// Usage: import and call launchConfetti(this.template) when you want to trigger confetti
export function launchConfetti(root) {
    if (!root) return;
    // Prevent multiple confetti overlays
    if (root.querySelector('.confetti-canvas')) return;
    
    const canvas = document.createElement('canvas');
    canvas.className = 'confetti-canvas';
    canvas.style.position = 'fixed';
    canvas.style.top = 0;
    canvas.style.left = 0;
    canvas.style.width = '100vw';
    canvas.style.height = '100vh';
    canvas.style.pointerEvents = 'none';
    canvas.style.zIndex = 9999;
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    root.appendChild(canvas);

    const ctx = canvas.getContext('2d');
    const confettiCount = 120;
    const confetti = [];
    const colors = ['#10b981', '#84cc16', '#f59e0b', '#f97316', '#ef4444', '#1b96ff', '#0176d3'];

    for (let i = 0; i < confettiCount; i++) {
        confetti.push({
            x: Math.random() * canvas.width,
            y: Math.random() * -canvas.height,
            r: 6 + Math.random() * 6,
            d: 8 + Math.random() * 8,
            color: colors[Math.floor(Math.random() * colors.length)],
            tilt: Math.random() * 10 - 10,
            tiltAngle: 0,
            tiltAngleIncrement: 0.05 + Math.random() * 0.07
        });
    }

    let frame = 0;
    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (let i = 0; i < confetti.length; i++) {
            const c = confetti[i];
            ctx.beginPath();
            ctx.ellipse(c.x, c.y, c.r, c.r / 2, c.tilt, 0, 2 * Math.PI);
            ctx.fillStyle = c.color;
            ctx.fill();
        }
        update();
        frame++;
        if (frame < 180) {
            requestAnimationFrame(draw);
        } else {
            root.removeChild(canvas);
        }
    }

    function update() {
        for (let i = 0; i < confetti.length; i++) {
            const c = confetti[i];
            c.y += (Math.cos(frame / 10) + c.d) / 2;
            c.x += Math.sin(frame / 20) * 2;
            c.tilt += c.tiltAngleIncrement;
            if (c.y > canvas.height + 20) {
                c.x = Math.random() * canvas.width;
                c.y = -10;
            }
        }
    }
    draw();
}
