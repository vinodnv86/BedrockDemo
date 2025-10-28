import { LightningElement, api } from 'lwc';
import getDefinitions from '@salesforce/apex/ProcessDefinitionService.getDefinitions';

export default class ProcessActionMenu extends LightningElement {
    @api recordId;
    @api objectApiName;

    processItems = [];
    error;

    showModal = false;
    modalTitle = '';
    modalComponentName = '';
    selectedVariationId;
    selectedFieldNames = '';
    selectedObjectApiName = '';

    connectedCallback() {
        this.loadDefinitions();
    }

    loadDefinitions() {
        getDefinitions({ recordId: this.recordId, objectApiName: this.objectApiName })
            .then(result => {
                this.processItems = result;
                this.error = undefined;
                console.log('Loaded process definitions:', this.processItems);
            })
            .catch(error => {
                this.error = error.body?.message || error.message;
                this.processItems = [];
            });
    }

    handleMenuSelect(event) {
        const selectedId = event.detail.value;
        const selected = this.processItems.find(item => item.variationId === selectedId);
        if (selected) {
            this.selectedVariationId = selected.variationId;
            this.modalComponentName = selected.modalComponentName;
            this.modalTitle = selected.label;
            this.selectedFieldNames = selected.fieldNames;        // 👈 New
            this.selectedObjectApiName = selected.objectApiName;  // 👈 New
            this.showModal = true;

            console.log('Selected process item:', selected);
        }
    }

    handleModalClose() {
        this.showModal = false;
        this.loadDefinitions(); // Optional: Refresh
        this.dispatchEvent(new CustomEvent('actioncompleted', {
            detail: { variationId: this.selectedVariationId }
        }));
    }
}
