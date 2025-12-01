import { LightningElement, api, track } from 'lwc';
import getButtonAccess from '@salesforce/apex/ObjectActionController.getButtonAccess';
import getFieldsForObject from '@salesforce/apex/ObjectActionController.getFieldsForObject';
import getRelatedAccount from '@salesforce/apex/ObjectActionController.getRelatedAccount';

export default class Generalchevronnew extends LightningElement {
      @api recordId;
        @track rows = [];
        @track showModal = false;
        @track modalTitle = '';
        @track modalFields = [];
        @track modalRecordId;
        @track modalObjectApi;
        @track formMode = 'view'; // view / create / update
        @track isHierarchy = false;
    
        connectedCallback() {
            getButtonAccess()
                .then(result => {
                    this.rows = result.map(row => ({
                        api: row.Object_Name__c,
                        label: row.Object_Name__c,
                        access: {
                            view: row.View__c,
                            create: row.Create__c,
                            update: row.Update__c
                        }
                    }));
                })
                .catch(error => {
                    console.error('Error fetching button access:', error);
                });
        }
    
        handleAction(event) {
            const api = event.target.dataset.api;
            const action = event.target.dataset.action;
            this.modalObjectApi = api;
            this.modalTitle = `${action} ${api}`;
            this.formMode = action.toLowerCase();
            this.isHierarchy = api.toLowerCase() === 'hierarchy';
    
            if (api === 'Account' && action.toLowerCase() === 'update') {
                getRelatedAccount({ recordId: this.recordId })
                    .then(accId => {
                        this.modalRecordId = accId;
                        return getFieldsForObject({ modalObjectApi: api });
                    })
                    .then(fields => {
                        this.modalFields = fields;
                        this.showModal = true;
                    })
                    .catch(error => console.error(error));
                return;
            }
    
            if (action.toLowerCase() === 'update' || action.toLowerCase() === 'view') {
                this.modalRecordId = this.recordId;
                getFieldsForObject({ modalObjectApi: api })
                    .then(fields => {
                        this.modalFields = fields;
                        this.showModal = true;
                    })
                    .catch(error => console.error(error));
                return;
            }
    
            if (action.toLowerCase() === 'create') {
                this.modalRecordId = null; // for create
                getFieldsForObject({ modalObjectApi: api })
                    .then(fields => {
                        this.modalFields = fields;
                        this.showModal = true;
                    })
                    .catch(error => console.error(error));
                return;
            }
        }
    
        closeModal() {
            this.showModal = false;
            this.modalFields = [];
        }
}