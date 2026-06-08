/**
 * @description Capa de Servicio que centraliza la lógica de negocio de Shipment__c.
 * @author Alejo De Urrengoechea
 */
public with sharing class ShipmentService {

    /**
     * @description Actualiza de forma masiva los Orders padre a "Shipped".
     * @param newShipments Lista de Shipment__c recién insertados.
     */
    public static void updateOrdersToShipped(List<Shipment__c> newShipments) {

        Set<Id> orderIds = new Set<Id>();
        for (Shipment__c shipment : newShipments) {
            if (shipment.Order__c != null) {
                orderIds.add(shipment.Order__c);
            }
        }

        if (orderIds.isEmpty()) {
            return;
        }

        List<Order> ordersToUpdate = new List<Order>();
        for (Id orderId : orderIds) {
            ordersToUpdate.add(new Order(
                Id                  = orderId,
                Logistics_Status__c = AppConstants.ORDER_STATUS_SHIPPED
            ));
        }

        update ordersToUpdate;
    }
}