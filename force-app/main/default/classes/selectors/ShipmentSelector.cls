/**
 * @description Clase Selectora que centraliza todas las consultas SOQL del objeto Shipment__c.
 * @author Alejo De Urrengoechea
 */
public with sharing class ShipmentSelector {

    /**
     * @description Obtiene un registro de Shipment__c por su número de tracking.
     * @param trackingNumber Número de tracking devuelto por Shippo.
     * @return Lista con el Shipment__c encontrado, o lista vacía si no existe.
     */
    public static List<Shipment__c> getShipmentByTrackingNumber(String trackingNumber) {
        if (!SObjectAccessUtil.isAccessible(Shipment__c.SObjectType)) {
            return new List<Shipment__c>();
        }

        return [
            SELECT Id, Order__c, Tracking_Number__c, Carrier__c
            FROM Shipment__c
            WHERE Tracking_Number__c = :trackingNumber
            LIMIT 1
        ];
    }

    /**
     * @description Obtiene el Shipment__c con su historial de Tracking_Event__c.
     * @param orderId ID del Order a consultar.
     * @return Lista con el Shipment__c y sus eventos, o lista vacía si no existe.
     */
    public static List<Shipment__c> getShipmentWithTrackingEvents(Id orderId) {
        if (!SObjectAccessUtil.isAccessible(Shipment__c.SObjectType)) {
            return new List<Shipment__c>();
        }

        return [
            SELECT Id, Name, Tracking_Number__c, Carrier__c, Label_URL__c,
                (
                    SELECT Id, Status_Code__c, Event_Date__c
                    FROM Tracking_Events__r
                    ORDER BY Event_Date__c DESC
                )
            FROM Shipment__c
            WHERE Order__c = :orderId
            LIMIT 1
        ];
    }
}