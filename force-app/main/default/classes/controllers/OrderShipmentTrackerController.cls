/**
 * @description Controlador Apex para el componente LWC orderShipmentTracker.
 * @author Alejo De Urrengoechea
 */
public with sharing class OrderShipmentTrackerController {

    /**
     * @description Obtiene el Shipment__c y su historial de tracking para un registro de Order.
     * @param orderId ID del Order a consultar.
     * @return Wrapper con los datos del envío o null si no existe.
     */
    @AuraEnabled(cacheable=true)
    public static ShipmentWrapper getShipmentData(Id orderId) {
        if (orderId == null) {
            return null;
        }

        List<Shipment__c> shipments = ShipmentSelector.getShipmentWithTrackingEvents(orderId);

        if (shipments.isEmpty()) {
            return null;
        }

        return new ShipmentWrapper(shipments[0]);
    }

    /**
     * @description Wrapper que encapsula los datos del Shipment__c y su historial de Tracking_Event__c.
     */
    public class ShipmentWrapper {
        @AuraEnabled public String shipmentId     {get; set;}
        @AuraEnabled public String shipmentName   {get; set;}
        @AuraEnabled public String trackingNumber {get; set;}
        @AuraEnabled public String carrier        {get; set;}
        @AuraEnabled public String labelUrl       {get; set;}
        @AuraEnabled public List<TrackingEventWrapper> trackingEvents {get; set;}

        public ShipmentWrapper(Shipment__c shipment) {
            this.shipmentId     = shipment.Id;
            this.shipmentName   = shipment.Name;
            this.trackingNumber = shipment.Tracking_Number__c;
            this.carrier        = shipment.Carrier__c;
            this.labelUrl       = shipment.Label_URL__c;
            this.trackingEvents = new List<TrackingEventWrapper>();

            if (shipment.Tracking_Events__r != null) {
                for (Tracking_Event__c te : shipment.Tracking_Events__r) {
                    this.trackingEvents.add(new TrackingEventWrapper(te));
                }
            }
        }
    }

    /**
     * @description Wrapper para cada evento de tracking del historial.
     */
    public class TrackingEventWrapper {
        @AuraEnabled public String   statusCode {get; set;}
        @AuraEnabled public DateTime eventDate  {get; set;}

        public TrackingEventWrapper(Tracking_Event__c te) {
            this.statusCode = te.Status_Code__c;
            this.eventDate  = te.Event_Date__c;
        }
    }
}