/**
 * @description Trigger principal para el objeto Shipment__c.
 * @author Alejo De Urrengoechea
 */
trigger ShipmentTrigger on Shipment__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        ShipmentTriggerHandler.handleAfterInsert(Trigger.new);
    }
}