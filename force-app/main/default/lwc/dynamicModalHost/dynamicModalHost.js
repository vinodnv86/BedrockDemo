import { LightningElement, api } from 'lwc';

export default class dynamicModalHost extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api variationId;
    @api modalTitle;
    @api fieldNames; 
  

    connectedCallback() {
    console.log('DynamicModalHost rendered!');
        console.log('variationId:', this.variationId);
        console.log('modalTitle:', this.modalTitle);
        console.log('recordId:', this.recordId);
        console.log('objectApiName:', this.objectApiName);
        console.log('fieldNames:', this.fieldNames);
}

    get shouldShowModal() {
        console.log('Modal visibility checked: ' + this.variationId);
        return this.variationId !== null && this.variationId !== undefined;
        
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
