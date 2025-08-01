import { loadStyle } from 'lightning/platformResourceLoader';
import unifiedStyles from '@salesforce/resourceUrl/unifiedStyles';

/**
 * Utility function to load unified styles in any LWC component
 * Call this in connectedCallback() of your component
 */
export async function loadUnifiedStyles(component) {
    if (!component._unifiedStylesLoaded) {
        try {
            await loadStyle(component, unifiedStyles);
            component._unifiedStylesLoaded = true;
        } catch (error) {
            console.error('Error loading unified styles:', error);
        }
    }
}
