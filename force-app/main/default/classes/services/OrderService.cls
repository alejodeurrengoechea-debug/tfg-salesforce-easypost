/**
 * @description Capa de Servicio que centraliza la lógica de negocio del objeto Order.
 * @author Alejo De Urrengoechea
 */
public with sharing class OrderService {

    /**
     * @description Evalúa de forma masiva qué Orders han cambiado su
     *              Logistics_Status__c a "Ready to Ship".
     * @param newOrders Lista de registros actualizados (Trigger.new).
     * @param oldMap    Mapa con el estado anterior de cada registro (Trigger.oldMap).
     */
    public static void processReadyToShip(
        List<Order> newOrders,
        Map<Id, Order> oldMap
    ) {
        Set<Id> orderIdsToProcess = new Set<Id>();

        for (Order newOrder : newOrders) {
            Order oldOrder = oldMap.get(newOrder.Id);

            Boolean statusChangedToReady =
                newOrder.Logistics_Status__c == AppConstants.ORDER_STATUS_READY_TO_SHIP &&
                oldOrder.Logistics_Status__c != AppConstants.ORDER_STATUS_READY_TO_SHIP;

            if (statusChangedToReady) {
                orderIdsToProcess.add(newOrder.Id);
            }
        }

        if (!orderIdsToProcess.isEmpty()) {
            System.enqueueJob(new ShippoQueueable(orderIdsToProcess));
        }
    }
}