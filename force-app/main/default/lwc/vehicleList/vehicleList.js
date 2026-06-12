import { LightningElement, wire } from 'lwc';
import getVehicleList from '@salesforce/apex/FleetManagementController.getVehicleList';

export default class VehicleList extends LightningElement {
    vehicles;
    error;

    @wire(getVehicleList)
    wiredVehicles({ error, data }) {
        if (data) {
            this.vehicles = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.vehicles = undefined;
        }
    }
}