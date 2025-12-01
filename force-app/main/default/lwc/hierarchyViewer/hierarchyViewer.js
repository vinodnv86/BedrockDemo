import { LightningElement, api, wire, track } from 'lwc';
import getHierarchy from '@salesforce/apex/ObjectActionController.getHierarchy';

export default class HierarchyViewer extends LightningElement {

    @api recordId;
    @api objectApiName;

    @track treeData = [];

    columns = [
        { label: 'Record', fieldName: 'name', type: 'text' }
    ];

    @wire(getHierarchy, { recordId: '$recordId', objectApiName: '$objectApiName' })
    loadHierarchy({ data }) {
        if (data) {
            this.treeData = [{
                id: this.recordId,
                name: 'Root Record (' + this.objectApiName + ')',
                _children: data.map(c => ({
                    id: c.id,
                    name: c.name
                }))
            }];
        }
    }
}
