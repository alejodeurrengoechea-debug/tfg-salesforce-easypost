import { LightningElement, api, wire } from "lwc";
import getShipmentData from "@salesforce/apex/OrderShipmentTrackerController.getShipmentData";

export default class OrderShipmentTracker extends LightningElement {
    @api recordId;

    shipment;
    error;
    isLoading = true;

    @wire(getShipmentData, { orderId: "$recordId" })
    wiredShipment({ data, error }) {
        this.isLoading = false;
        if (data) {
            // Formateamos las fechas de los eventos para mostrarlas de forma legible
            this.shipment = {
                ...data,
                trackingEvents: data.trackingEvents.map(event => ({
                    ...event,
                    formattedDate: event.eventDate
                        ? new Date(event.eventDate).toLocaleString('es-ES', {
                            day: '2-digit', month: '2-digit', year: 'numeric',
                            hour: '2-digit', minute: '2-digit'
                          })
                        : ''
                }))
            };
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || "An unexpected error occurred.";
            this.shipment = undefined;
        }
    }

    get isEmpty() {
        return !this.isLoading && !this.shipment && !this.error;
    }

    get hasShipment() {
        return !this.isLoading && this.shipment != null;
    }

    get hasTrackingEvents() {
        return this.shipment?.trackingEvents?.length > 0;
    }

    handlePrintLabel() {
        window.open(this.shipment.labelUrl, "_blank");
    }
}