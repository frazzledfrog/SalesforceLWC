import { LightningElement } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';
import VIN_Amendment from '@salesforce/resourceUrl/VIN_Amendment';
import Trustee_Form from '@salesforce/resourceUrl/Trustee_Form';
import RecSheetPDF from '@salesforce/resourceUrl/RecSheetPDF';
import Dealer_Sign_Up_Package_ENG from '@salesforce/resourceUrl/Dealer_Sign_Up_Package_ENG';
import Dealer_Sign_Up_Package_FR from '@salesforce/resourceUrl/Dealer_Sign_Up_Package_FR';
import Proof_of_Insurance_Form from '@salesforce/resourceUrl/Proof_of_Insurance_Form';

export default class QuickPdfs extends LightningElement {
    pdfFiles = [
        {
            id: 'vin_amendment',
            name: 'VIN Amendment',
            resourceUrl: VIN_Amendment
        },
        {
            id: 'trustee_form',
            name: 'Trustee Form',
            resourceUrl: Trustee_Form
        },
        {
            id: 'rec_sheet_pdf',
            name: 'Recreational Vehicle Finance Sheet',
            resourceUrl: RecSheetPDF
        },
        {
            id: 'dealer_signup_eng',
            name: 'Dealer Sign Up Package (English)',
            resourceUrl: Dealer_Sign_Up_Package_ENG
        },
        {
            id: 'dealer_signup_fr',
            name: 'Dealer Sign Up Package (French)',
            resourceUrl: Dealer_Sign_Up_Package_FR
        },
        {
            id: 'proof_of_insurance',
            name: 'Proof of Insurance Form',
            resourceUrl: Proof_of_Insurance_Form
        }
    ];

    get hasPdfFiles() {
        return this.pdfFiles && this.pdfFiles.length > 0;
    }

    handlePreview(event) {
        const fileId = event.target.dataset.fileId;
        const file = this.pdfFiles.find(f => f.id === fileId);
        
        if (file && file.resourceUrl) {
            window.open(file.resourceUrl, '_blank');
        }
    }

    handleDownload(event) {
        const fileId = event.target.dataset.fileId;
        const file = this.pdfFiles.find(f => f.id === fileId);
        
        if (file && file.resourceUrl) {
            const link = document.createElement('a');
            link.href = file.resourceUrl;
            link.download = file.name + '.pdf';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }

    async connectedCallback() {
        // Load unified styles
        await loadUnifiedStyles(this);

        console.log('PDF Files loaded:', this.pdfFiles);
        console.log('VIN_Amendment URL:', VIN_Amendment);
        console.log('Trustee_Form URL:', Trustee_Form);
        console.log('RecSheetPDF URL:', RecSheetPDF);
        console.log('Dealer_Sign_Up_Package_ENG URL:', Dealer_Sign_Up_Package_ENG);
        console.log('Dealer_Sign_Up_Package_FR URL:', Dealer_Sign_Up_Package_FR);
        console.log('Proof_of_Insurance_Form URL:', Proof_of_Insurance_Form);
    }
}
