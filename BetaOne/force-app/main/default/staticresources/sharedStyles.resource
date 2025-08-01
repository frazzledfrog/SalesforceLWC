/* ==============================================
   SHARED DESIGN SYSTEM STYLES
   Global CSS Custom Properties for All Components
   ============================================== */

/* Define shared design tokens that can be used across all components */
:root {
    /* SLDS Brand Colors */
    --brand-primary: #1b96ff;                    /* PALETTE_BLUE_60 */
    --brand-accessible: #0176d3;                /* PALETTE_BLUE_50 */
    --brand-dark: #014486;                      /* PALETTE_BLUE_30 */
    --brand-light: #f4f6fe;                     /* BRAND_LIGHT */
    
    /* SLDS Status Colors */
    --success-color-rgb: 69, 198, 90;
    --success-color: rgb(var(--success-color-rgb));
    --success-background: rgba(var(--success-color-rgb), 0.1);
    --error-color-rgb: 234, 0, 30;
    --error-color: rgb(var(--error-color-rgb));
    --error-background: rgba(var(--error-color-rgb), 0.1);
    --warning-color-rgb: 254, 147, 57;
    --warning-color: rgb(var(--warning-color-rgb));
    --warning-background: rgba(var(--warning-color-rgb), 0.1);
    --info-color-rgb: 116, 116, 116;
    --info-color: rgb(var(--info-color-rgb));
    --info-background: rgba(var(--info-color-rgb), 0.1);
    
    /* SLDS Background Colors */
    --background-color: #f3f3f3;                /* PALETTE_NEUTRAL_95 */
    --card-background-color: #ffffff;           /* PALETTE_NEUTRAL_100 */
    --secondary-background: var(--background-color);
    
    /* SLDS Text Colors */
    --text-color: #181818;                       /* PALETTE_NEUTRAL_10 */
    --text-muted: #444444;                       /* PALETTE_NEUTRAL_30 */
    --heading-color: var(--text-color);
    
    /* SLDS Border Colors */
    --border-color: #e5e5e5;                    /* PALETTE_NEUTRAL_90 */
    --border-light: #f3f3f3;                    /* PALETTE_NEUTRAL_95 */
    --shadow-color: rgba(0, 0, 0, 0.10);        /* SLDS Shadow tokens */
    
    /* Legacy color support for backward compatibility */
    --primary-color: var(--brand-primary);
    --primary-hover: var(--brand-accessible);
    --secondary-color: #1de9b6; /* Keep for accent */
    
    /* SLDS Typography - Matching Lightning Design System */
    --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol';
    --font-size-xs: 0.625rem;      /* FONT_SIZE_1 - 10px */
    --font-size-sm: 0.75rem;       /* FONT_SIZE_2 - 12px */
    --font-size-base: 0.875rem;    /* FONT_SIZE_4 - 14px */
    --font-size-lg: 1rem;          /* FONT_SIZE_5 - 16px */
    --font-size-xl: 1.125rem;      /* FONT_SIZE_6 - 18px */
    --font-size-xxl: 1.25rem;      /* FONT_SIZE_7 - 20px */
    --font-size-xxxl: 1.5rem;      /* FONT_SIZE_8 - 24px */
    
    /* SLDS Font Weights */
    --font-weight-light: 300;
    --font-weight-normal: 400;
    --font-weight-medium: 500;
    --font-weight-semibold: 600;
    --font-weight-bold: 700;
    
    /* SLDS Line Heights */
    --line-height-tight: 1.25;      /* LINE_HEIGHT_HEADING */
    --line-height-normal: 1.4;
    --line-height-relaxed: 1.5;     /* LINE_HEIGHT_TEXT */
    
    /* SLDS Spacing Tokens */
    --spacing-xs: 0.25rem;           /* SPACING_XX_SMALL - 4px */
    --spacing-small: 0.5rem;         /* SPACING_X_SMALL - 8px */
    --spacing-medium: 1rem;          /* SPACING_MEDIUM - 16px */
    --spacing-large: 1.5rem;         /* SPACING_LARGE - 24px */
    --spacing-xl: 2rem;              /* SPACING_X_LARGE - 32px */
    --spacing-xxl: 3rem;             /* SPACING_XX_LARGE - 48px */
    
    /* SLDS Border Radius */
    --border-radius: 0.25rem;        /* BORDER_RADIUS_MEDIUM - 4px */
    --border-radius-lg: 0.5rem;      /* BORDER_RADIUS_LARGE - 8px */
    --border-radius-small: 0.125rem; /* BORDER_RADIUS_SMALL - 2px */
    
    /* SLDS Shadows */
    --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
    --shadow-md: 0 2px 2px 0 rgba(0, 0, 0, 0.10);
    --shadow-lg: 0 2px 3px 0 rgba(0, 0, 0, 0.16);
}

/* Common utility classes that can be used across components */
.shared-card {
    background: var(--card-background-color);
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-md);
}

.shared-header {
    background: linear-gradient(135deg, var(--brand-dark) 0%, var(--brand-primary) 100%);
    color: white;
    padding: var(--spacing-small) var(--spacing-medium);
}

.shared-title {
    font-size: var(--font-size-lg);
    font-weight: var(--font-weight-semibold);
    color: var(--heading-color);
    margin: 0;
}

.shared-text {
    font-size: var(--font-size-base);
    color: var(--text-color);
    line-height: var(--line-height-normal);
}

.shared-text-muted {
    color: var(--text-muted);
    font-size: var(--font-size-sm);
}

.shared-button-primary {
    background: var(--brand-accessible);
    border: 1px solid var(--brand-accessible);
    color: white;
    padding: var(--spacing-xs) var(--spacing-medium);
    border-radius: var(--border-radius);
    font-weight: var(--font-weight-medium);
    transition: all 0.2s ease;
}

.shared-button-primary:hover {
    background: var(--brand-dark);
    border-color: var(--brand-dark);
}

.shared-button-secondary {
    background: var(--secondary-color);
    border: 1px solid var(--secondary-color);
    color: white;
    padding: var(--spacing-xs) var(--spacing-medium);
    border-radius: var(--border-radius);
    font-weight: var(--font-weight-medium);
    transition: all 0.2s ease;
}

.shared-button-secondary:hover {
    background: rgba(29, 233, 182, 0.8);
    border-color: rgba(29, 233, 182, 0.8);
}

/* Responsive utilities */
.shared-hide-mobile {
    display: block;
}

.shared-show-mobile {
    display: none;
}

@media (max-width: 768px) {
    .shared-hide-mobile {
        display: none;
    }
    
    .shared-show-mobile {
        display: block;
    }
}
