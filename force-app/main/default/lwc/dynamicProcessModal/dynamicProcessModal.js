import { LightningElement, api } from 'lwc';

export default class DynamicProcessModal extends LightningElement {
    @api variationId;
    @api recordId;
    @api objectApiName;
    @api fieldNames;
    @api modalTitle;

    connectedCallback() {
        console.log('DynamicProcessModal connectedCallback!');
        console.log('fieldNames:', this.fieldNames);
    }

    renderedCallback() {
        console.log('Rendered with fieldList:', this.fieldList);
    }

    get fieldList() {
        return this.fieldNames
            ? this.fieldNames.split(',').map(f => f.trim())
            : [];
    }

    get modeEdit() {
        return ['updateOpportunity', 'updateCustomer'].includes(this.variationId);
    }

    handleSuccess() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
