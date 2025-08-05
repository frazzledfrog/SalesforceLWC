import { loadStyle } from 'lightning/platformResourceLoader';
import unifiedStyles from '@salesforce/resourceUrl/unifiedStyles';

/**
 * Loads the shared stylesheet into a Lightning Web Component.
 * Ensures the resource is only applied once per component instance.
 *
 * @param {LightningElement} component - The component requesting styles.
 * @returns {Promise<void>} Resolves when the stylesheet is loaded.
 */
export async function loadUnifiedStyles(component) {
    if (!component._unifiedStylesLoaded) {
        try {
            await loadStyle(component, unifiedStyles);
            component._unifiedStylesLoaded = true;
        } catch (error) {
            // eslint-disable-next-line no-console
            console.error('Error loading unified styles:', error);
        }
    }
}

/**
 * Mixin that automatically loads unified styles during component initialization.
 * Use by extending your component with `withUnifiedStyles(BaseClass)`.
 *
 * @param {typeof LightningElement} Base - The base component class to extend.
 * @returns {typeof LightningElement} A subclass that loads styles in connectedCallback.
 */
export const withUnifiedStyles = (Base) => class extends Base {
    async connectedCallback() {
        await loadUnifiedStyles(this);
        if (super.connectedCallback) {
            await super.connectedCallback();
        }
    }
};
