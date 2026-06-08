/**
 * @description Handler del trigger de Shipment__c.
 * @author Alejo De Urrengoechea
 */
public with sharing class ShipmentTriggerHandler {

    /**
     * @description Maneja el contexto after insert de Shipment__c.
     * @param newShipments Lista de registros insertados (Trigger.new).
     */
    public static void handleAfterInsert(List<Shipment__c> newShipments) {
        if (newShipments == null || newShipments.isEmpty()) {
            return;
        }

        ShipmentService.updateOrdersToShipped(newShipments);
    }
}