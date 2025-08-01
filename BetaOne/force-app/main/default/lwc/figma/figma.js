import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import sharedStyles from '@salesforce/resourceUrl/sharedStyles';

export default class Figma extends LightningElement {
    
    connectedCallback() {
        // Load shared styles (same as quickpdfs app)
        loadStyle(this, sharedStyles)
            .then(() => {
                console.log('Shared styles loaded successfully in FIGMA app');
            })
            .catch(error => {
                console.error('Error loading shared styles in FIGMA app:', error);
            });
    }
}
