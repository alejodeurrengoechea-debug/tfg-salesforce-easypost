import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import LOGISTICS_STATUS_FIELD from "@salesforce/schema/Order.Logistics_Status__c";
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

const EMPTY_STATE_MESSAGES = {
    'Draft':         'This order is still in draft. Activate it and set it to Ready to Ship to create a shipment.',
    'Ready to Ship': 'The shipment is being processed. It will appear here shortly.',
    'Cancelled':     'This order has been cancelled. No shipment will be created.',
    'default':       'No shipment has been created for this order yet.',
};

export default class OrderShipmentTracker extends LightningElement {
    @api recordId;
    @api logisticsStatus; // Mantenida por compatibilidad con App Builder

    shipment;
    error;
    isLoading = true;
    orderRecord;

    @wire(getRecord, { recordId: "$recordId", fields: [LOGISTICS_STATUS_FIELD] })
    wiredOrder({ data, error }) {
        if (data) {
            this.orderRecord = data;
        }
    }

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

    get emptyStateMessage() {
        const status = this.orderRecord
            ? getFieldValue(this.orderRecord, LOGISTICS_STATUS_FIELD)
            : null;
        return EMPTY_STATE_MESSAGES[status] || EMPTY_STATE_MESSAGES['default'];
    }

    handlePrintLabel() {
        window.open(this.shipment.labelUrl, "_blank");
    }
}