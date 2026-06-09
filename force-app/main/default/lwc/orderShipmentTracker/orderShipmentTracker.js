import { LightningElement, api, wire } from "lwc";
import getShipmentData from "@salesforce/apex/OrderShipmentTrackerController.getShipmentData";

const STATUS_ICON_MAP = {
    DELIVERED:        "utility:success",
    IN_TRANSIT:       "utility:truck",
    OUT_FOR_DELIVERY: "utility:location",
    FAILURE:          "utility:error",
    RETURNED:         "utility:undo",
    UNKNOWN:          "utility:help",
};

const STATUS_VARIANT_MAP = {
    DELIVERED:        "success",
    IN_TRANSIT:       "brand",
    OUT_FOR_DELIVERY: "warning",
    FAILURE:          "error",
    RETURNED:         "error",
    UNKNOWN:          "default",
};

const CARRIER_TRACKING_URL = {
    USPS:    "https://tools.usps.com/go/TrackConfirmAction?tLabels=",
    UPS:     "https://www.ups.com/track?tracknum=",
    FEDEX:   "https://www.fedex.com/fedextrack/?trknbr=",
    DHL:     "https://www.dhl.com/en/express/tracking.html?AWB=",
    CORREOS: "https://www.correos.es/es/es/herramientas/localizador/envios/detalle?tracking-number=",
};

export default class OrderShipmentTracker extends LightningElement {
    @api recordId;

    shipment;
    error;
    isLoading = true;

    @wire(getShipmentData, { orderId: "$recordId" })
    wiredShipment({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.shipment = {
                ...data,
                trackingEvents: data.trackingEvents.map(event => ({
                    ...event,
                    formattedDate: event.eventDate
                        ? new Date(event.eventDate).toLocaleString('es-ES', {
                            day: '2-digit', month: '2-digit', year: 'numeric',
                            hour: '2-digit', minute: '2-digit'
                          })
                        : '',
                    icon: STATUS_ICON_MAP[event.statusCode] || "utility:help"
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

    get currentStatus() {
        if (!this.shipment?.trackingEvents?.length) {
            return null;
        }
        return this.shipment.trackingEvents[0];
    }

    get currentStatusVariant() {
        if (!this.currentStatus) {
            return "default";
        }
        return STATUS_VARIANT_MAP[this.currentStatus.statusCode] || "default";
    }

    get currentStatusCssClass() {
        return `status-${this.currentStatusVariant}`;
    }

    get trackingUrl() {
        if (!this.shipment?.trackingNumber || !this.shipment?.carrier) {
            return null;
        }
        const baseUrl = CARRIER_TRACKING_URL[this.shipment.carrier.toUpperCase()];
        return baseUrl ? `${baseUrl}${this.shipment.trackingNumber}` : null;
    }

    handlePrintLabel() {
        window.open(this.shipment.labelUrl, "_blank");
    }
}