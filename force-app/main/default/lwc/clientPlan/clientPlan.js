import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import leafletLib from '@salesforce/resourceUrl/leaflet';
import leafletImageLib from '@salesforce/resourceUrl/leafletImage';
import saveMapImage from '@salesforce/apex/ClientPlanController.saveMapImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ClientPlan extends LightningElement {
    @api recordId;
    mapInitialized = false;
    map;

    renderedCallback() {
        if (this.mapInitialized) return;
        this.mapInitialized = true;

        Promise.all([
            loadScript(this, leafletLib + '/leaflet/leaflet.js'),
            loadStyle(this, leafletLib + '/leaflet/leaflet.css'),
            loadScript(this, leafletImageLib)
        ])
        .then(() => this.initMap())
        .catch(error => {
            console.error('Error loading libraries', error);
        });
    }

    initMap() {
        const mapEl = this.template.querySelector('.map-container');
        mapEl.style.height = '400px';

        this.map = L.map(mapEl).setView([20, 0], 2);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap contributors'
        }).addTo(this.map);

        // Click to drop pin
        this.map.on('click', async (e) => {
            const { lat, lng } = e.latlng;
            L.marker([lat, lng])
                .addTo(this.map)
                .bindPopup(`Lat: ${lat.toFixed(2)}, Lng: ${lng.toFixed(2)}`)
                .openPopup();
console.log('Map clicked at', lat, lng);
            await this.captureMapImage();
            console.log('Map image captured and saved.');
        });
    }

    captureMapImage() {
        return new Promise((resolve, reject) => {
            if (!this.map || !window.leafletImage) {
                console.error('Map or leafletImage not initialized.');
                return reject('Leaflet or leafletImage not loaded.');
            }

            // Convert map to image using leaflet-image
            window.leafletImage(this.map, async (err, canvas) => {
                if (err) {
                    console.error('Error capturing map image', err);
                    console.error(err);
                    return reject(err);
                }
console.log('Map image captured to canvas.');
                const base64Image = canvas.toDataURL('image/png').split(',')[1];
console.log('Base64 image generated.');
                try {
                    await saveMapImage({ accountId: this.recordId, base64Image });
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!',
                            message: 'Map image saved to Files.',
                            variant: 'success'
                        })
                    );
                    resolve();
                } catch (e) {
                    console.error('Error saving image', e);
                    reject(e);
                }
            });
        });
    }
}
