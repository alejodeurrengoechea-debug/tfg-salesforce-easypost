/**
 * @description Handler encargado de la orquestación del trigger de Order.
 * @author: Alejo De Urrengoechea 
 */
 
public with sharing class OrderTriggerHandler {

    /**
     * @description Maneja el contexto before update del objeto Order.
     * @param newOrders Lista de registros en su estado nuevo (Trigger.new).
     * @param oldMap    Mapa de registros en su estado anterior (Trigger.oldMap).
     */
    public static void handleBeforeUpdate(
        List<Order> newOrders,
        Map<Id, Order> oldMap
    ) {
        if (newOrders == null || newOrders.isEmpty()) {
            return;
        }

        OrderService.validateReadyToShip(newOrders, oldMap);
    }

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