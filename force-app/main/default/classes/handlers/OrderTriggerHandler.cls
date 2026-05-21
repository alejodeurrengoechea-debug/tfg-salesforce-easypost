/**
 * @description Handler encargado de la orquestación del trigger de Order.
 * @author: Alejo De Urrengoechea 
 */
 
public with sharing class OrderTriggerHandler {

    /**
     * @param newOrders  Lista de registros en su estado nuevo (Trigger.new).
     * @param oldMap     Mapa de registros en su estado anterior (Trigger.oldMap).
     */
    public static void handleAfterUpdate(
        List<Order> newOrders,
        Map<Id, Order> oldMap
    ) {
        if (newOrders == null || newOrders.isEmpty()) {
            return;
        }

        // Delegamos a la capa de servicio pasando el oldMap para que pueda detectar el cambio de estado
        OrderService.processReadyToShip(newOrders, oldMap);
    }
}