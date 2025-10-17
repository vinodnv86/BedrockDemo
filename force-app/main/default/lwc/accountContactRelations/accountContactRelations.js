import { LightningElement, api, track, wire } from 'lwc';
import getRelatedContacts from '@salesforce/apex/AccountContactRelationController.getRelatedContacts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountContactRelations extends LightningElement {
    @api recordId; // Account Id
    @api maxRecords = 10; // Default max records
    @track sortBy = 'Name'; // Default sort

    @track contacts = [];
    @track error;

    // Columns for datatable
    columns = [
        {
            label: 'Contact Name',
            fieldName: 'contactUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'contactName' }, target: '_blank' }
        },
        { label: 'Email', fieldName: 'contactEmail', type: 'email' },
        { label: 'Phone', fieldName: 'contactPhone', type: 'phone' },
        { label: 'Relationship Count', fieldName: 'relationCount', type: 'number' }
    ];

    // Wire Apex method
    @wire(getRelatedContacts, { accountId: '$recordId', limitSize: '$maxRecords', sortBy: '$sortBy' })
    wiredContacts({ data, error }) {
        if (data) {
            this.contacts = data.map(c => ({
                ...c,
                contactUrl: '/' + c.contactId
            }));
            this.error = undefined;
        } else if (error) {
            this.contacts = [];
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading related contacts',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        }
    }
    get sortOptions() {
    return [
        { label: 'Name', value: 'Name' },
        { label: 'Relationship Count', value: 'Count' }
    ];
}

    get hasContacts() {
        return this.contacts && this.contacts.length > 0;
    }

    // Handle sort dropdown change
    handleSortChange(event) {
        this.sortBy = event.target.value;
    }
}
