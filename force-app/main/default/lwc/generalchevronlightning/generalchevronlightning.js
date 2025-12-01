import { LightningElement, api, track, wire } from 'lwc';
import getObjectName from '@salesforce/apex/ObjectActionController.getObjectName';
import getAccessForObject from '@salesforce/apex/ObjectActionController.getAccessForObject';
import getButtonAccess from '@salesforce/apex/ObjectActionController.getButtonAccess';
import getRelatedAccount from '@salesforce/apex/ObjectActionController.getRelatedAccount';
import getFieldsForObject from '@salesforce/apex/ObjectActionController.getFieldsForObject';
import createTask from '@salesforce/apex/ObjectActionController.createTask'; // New import for creating Task

export default class GeneralChevronLightning extends LightningElement {
    @api recordId;

    @track currentObjectApiName;
    @track rows = [];

    // Modal state
    @track showModal = false;
    @track modalTitle = '';
    @track modalObjectApi;
    @track modalRecordId;
    @track modalFields = [];
    @track formMode = 'view';
    @track isHierarchy = false;

 // -----------------------
    // 1) INITIAL LOAD
    // -----------------------
    connectedCallback() {
        console.log('ConnectedCallback running…');

        if (!this.recordId) {
            console.error('No recordId found');
            return;
        }

        // Get object API name first
        getObjectName({ recordId: this.recordId })
            .then(objName => {
                this.currentObjectApiName = objName;
                console.log('Current Object:', objName);

                // Now load button access rows for this object
                this.loadButtonAccess(objName);
            })
            .catch(error => {
                console.error('Error fetching object name', error);
            });
    }

    // -----------------------
    // 2) LOAD BUTTON ACCESS
    // -----------------------
    loadButtonAccess(objName) {
        getAccessForObject({ parentObjectApiName: objName })
            .then(result => {
                console.log('Access rows from Apex:', result);

                this.rows = result.map(r => ({
                    id: r.Id,
                    api: r.Object_Name__c,
                    label: r.Object_Name__c,
                    access: {
                        view: r.View__c,
                        create: r.Create__c,
                        update: r.Update__c
                    }
                }));

                console.log('Formatted Rows:', this.rows);
            })
            .catch(err => {
                console.error('Error loading button access:', err);
            });
    }
get isEditMode() {
    return this.formMode === 'create' || this.formMode === 'update';
}
    // 3️⃣ Handle button click
    handleAction(event) {
        const api = event.target.dataset.api;
        const action = event.target.dataset.action;

        this.modalObjectApi = api;
        this.modalTitle = `${action} ${api}`;
        this.formMode = action;
        this.isHierarchy = api === 'Hierarchy';

        if (this.isHierarchy) {
            this.showModal = true;
            return;
        }

        // Handle special case: Update Account
        if (api === 'Account' && action === 'update') {
            console.log('Handling Account update special case');
            getRelatedAccount({ recordId: this.recordId })
                .then(accId => {
                    this.modalRecordId = accId;
                    console.log('Related Account ID:', accId);
                    return getFieldsForObject({ objectApiName: api });
                })
                .then(fields => {
                    console.log('Fields for Account:', fields);
                    this.modalFields = fields;
                    this.showModal = true;
                });
            return;
        }

        // Handle Create Task
        if (api === 'Task' && action === 'create') {
            console.log('Opening custom Task create form...');
            this.isTaskCreate = true;
            this.relatedToId = this.recordId;
            this.showModal = true;
            return;
        }
            // Reset Task custom form mode if not using Task
        this.isTaskCreate = false;
        // -----------------------------------------
   

 // -------------------------------------
    // CREATE A NEW RECORD
    // -------------------------------------
    if (action === 'create') {
        this.modalRecordId = null;  // new record
        console.log('Creating new', api);

        getFieldsForObject({ objectApiName: api })
            .then(fields => {
                console.log('Fields for new', api, ':', fields);
                this.modalFields = fields;
                this.showModal = true;
            })
            .catch(error => console.error('Error loading fields:', error));

        return;
    }

    // -------------------------------------
    // UPDATE EXISTING RECORD
    // -------------------------------------
    if (action === 'update') {
        this.modalRecordId = this.recordId;

        getFieldsForObject({ objectApiName: api })
            .then(fields => {
                this.modalFields = fields;
                console.log('Fields for', api, ':', fields);
                this.showModal = true;
            })
            .catch(error => console.error('Field Load Error:', error));

        return;
    }

    // -------------------------------------
    // VIEW MODE
    // -------------------------------------
   if (action === 'view') {

    // Special case: VIEW Account → must get related account ID
    if (api === 'Account') {
        console.log('VIEW Account → fetching related Account Id');

        getRelatedAccount({ recordId: this.recordId })
            .then(accId => {
                this.modalRecordId = accId;
                return getFieldsForObject({ objectApiName: api });
            })
            .then(fields => {
                console.log('Fields for Account:', fields);
                this.modalFields = fields;
                this.showModal = true;
            })
            .catch(error => console.error(error));

        return;
    }

    // Normal objects
    this.modalRecordId = this.recordId;

    getFieldsForObject({ objectApiName: api })
        .then(fields => {
            this.modalFields = fields;
            this.showModal = true;
        })
        .catch(error => console.error(error));

    return;
}

    }
    // -----------------------------------------
    // HANDLE TASK FIELD INPUTS
    // -----------------------------------------
    handleSubjectChange(event){
        this.subject = event.target.value;
    }

    handleDueDateChange(event) {
        this.dueDate = event.target.value;
    }

    // -----------------------------------------
    // CREATE TASK VIA APEX
    // -----------------------------------------
    async handleCreateTask() {
        try {
            const taskId = await createTask({
                subject: this.subject,
                dueDate: this.dueDate,
                relatedToId: this.relatedToId
            });

            console.log('Task created:', taskId);
            this.closeModal();

        } catch (error) {
            console.error('Task creation error:', error);
        }
    }

    closeModal() {
        this.showModal = false;
    }
}
