/**
 * @description Servicio que procesa los eventos de tracking recibidos desde Shippo.
 * @author Alejo De Urrengoechea
 */
public with sharing class ShippoWebhookService {

    /**
     * @description Procesa un evento de tracking.
     * @param trackingNumber Número de seguimiento del paquete.
     * @param statusCode     Código de estado devuelto por Shippo (ej. DELIVERED).
     * @param statusDate     Fecha del evento en formato ISO 8601.
     */
    public static void processTrackingEvent(
        String trackingNumber,
        String statusCode,
        String statusDate
    ) {
        List<Shipment__c> shipments = ShipmentSelector.getShipmentByTrackingNumber(trackingNumber);

        if (shipments == null || shipments.isEmpty()) {
            System.debug('WARNING: No se encontró Shipment__c con tracking number: ' + trackingNumber);
            return;
        }

        Shipment__c shipment = shipments[0];

        // Creamos el registro del evento de tracking
        Tracking_Event__c trackingEvent = new Tracking_Event__c(
            Shipment__c    = shipment.Id,
            Status_Code__c = statusCode,
            Event_Date__c  = parseDate(statusDate)
        );
        insert trackingEvent;

        // Si el paquete fue entregado actualizamos el Order a Delivered
        if (statusCode == AppConstants.ORDER_STATUS_DELIVERED && shipment.Order__c != null) {
            update new Order(
                Id                  = shipment.Order__c,
                Logistics_Status__c = AppConstants.ORDER_STATUS_DELIVERED
            );
        }
    }

    /**
     * @description Parsea una fecha ISO 8601 devuelta por Shippo a DateTime de Salesforce.
     * @param isoDate String de fecha en formato ISO 8601 (ej. 2026-05-21T10:00:00Z).
     * @return DateTime parseado, o null si el formato es inválido.
     */
    private static DateTime parseDate(String isoDate) {
        if (isoDate == null) {
            return null;
        }
        try {
            return (DateTime) JSON.deserialize('"' + isoDate + '"', DateTime.class);
        } catch (Exception e) {
            System.debug('WARNING: No se pudo parsear la fecha: ' + isoDate);
            return null;
        }
    }
}