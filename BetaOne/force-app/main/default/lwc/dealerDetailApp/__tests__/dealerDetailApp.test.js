import { createElement } from 'lwc';
import DealerDetailApp from 'c/dealerDetailApp';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import getDealerOptions from '@salesforce/apex/DealerDetailController.getDealerOptions';

jest.mock(
    'lightning/platformResourceLoader',
    () => {
        return {
            loadScript: jest.fn().mockResolvedValue()
        };
    },
    { virtual: true }
);

const getDealerOptionsAdapter = registerApexTestWireAdapter(getDealerOptions);

describe('c-dealer-detail-app', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders combobox', () => {
        const element = createElement('c-dealer-detail-app', { is: DealerDetailApp });
        document.body.appendChild(element);

        getDealerOptionsAdapter.emit([]);

        return Promise.resolve().then(() => {
            const combobox = element.shadowRoot.querySelector('lightning-combobox');
            expect(combobox).not.toBeNull();
        });
    });
});
