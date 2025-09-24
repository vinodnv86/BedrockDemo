import { LightningElement,wire,track,api } from 'lwc';

import getCompanyLocations from '@salesforce/apex/GoogleMapController.getCompanyLocations';

export default class googleMapLWC extends LightningElement {

   @api accountNameParam='Bedrock’s Corporate Headquarters';    
    @track error; 
    @track mapMarkers = [];
    @track markersTitle = 'Bedrock’s Corporate Headquarters';
    @track zoomLevel = 4;
//https://developer.salesforce.com/docs/component-library/bundle/lightning-map/documentation
    @wire(getCompanyLocations, { accountNameInitial: '$accountNameParam'})
    wiredOfficeLocations({ error, data }) {
        if (data) {            
            data.forEach(dataItem => {
                this.mapMarkers = [...this.mapMarkers ,
                    {
                        location: {
                            Street: dataItem.Street,
                            PostalCode: dataItem.PostalCode,
                            State: dataItem.State,
                            City: dataItem.City,
                            Country: dataItem.Country,
                        },
        
                        icon: 'standard:account',
                        title: dataItem.Name,
                    }                                    
                ];
              });            
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }

}