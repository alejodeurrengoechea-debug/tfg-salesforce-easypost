/**
 * @description Capa de Servicio que centraliza la lógica de negocio del objeto Order.
 * @author Alejo De Urrengoechea
 */
public with sharing class OrderService {

    /**
     * @description Filtra los Orders que están cambiando su estado a "Ready to Ship".
     * @param newOrders Lista de registros actualizados.
     * @param oldMap    Mapa con el estado anterior de cada registro.
     * @return Set de IDs de Orders que cumplen la condición.
     */
    private static Set<Id> getOrdersChangingToReadyToShip(
        List<Order> newOrders,
        Map<Id, Order> oldMap
    ) {
        Set<Id> result = new Set<Id>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldMap.get(newOrder.Id);
            if (newOrder.Logistics_Status__c == AppConstants.ORDER_STATUS_READY_TO_SHIP &&
                oldOrder.Logistics_Status__c != AppConstants.ORDER_STATUS_READY_TO_SHIP) {
                result.add(newOrder.Id);
            }
        }
        return result;
    }

    /**
     * @description Valida que los Orders que intentan cambiar a "Ready to Ship" tengan todos los datos obligatorios.
     * @param newOrders Lista de registros antes de guardarse (Trigger.new).
     * @param oldMap    Mapa con el estado anterior de cada registro.
     */
    public static void validateReadyToShip(
        List<Order> newOrders,
        Map<Id, Order> oldMap
    ) {
        // Acumulamos los IDs que intentan cambiar a Ready to Ship
        Set<Id> orderIdsToValidate = getOrdersChangingToReadyToShip(newOrders, oldMap);

        if (orderIdsToValidate.isEmpty()) {
            return;
        }

        Map<Id, Order> ordersWithItems = OrderSelector.getOrdersWithItemsForValidation(orderIdsToValidate);

        // Mapa para acceder a los registros de Trigger.new por Id
        Map<Id, Order> newOrdersMap = new Map<Id, Order>(newOrders);

        // Aplicamos las reglas de validación sobre cada regsitro Order
        for (Id orderId : orderIdsToValidate) {
            Order newOrder       = newOrdersMap.get(orderId);
            Order orderWithItems = ordersWithItems.get(orderId);

            // Regla 1: debe tener cuenta de envío
            if (newOrder.Ship_To_Account__c == null) {
                newOrder.addError('No se puede marcar como Ready to Ship: falta la cuenta de envío (Ship To Account).');
                continue;
            }

            // Regla 2: debe tener al menos un producto
            if (orderWithItems.OrderItems == null || orderWithItems.OrderItems.isEmpty()) {
                newOrder.addError('No se puede marcar como Ready to Ship: el pedido no tiene líneas de producto.');
                continue;
            }

            // Regla 3: todos los productos deben tener datos físicos completos
            for (OrderItem item : orderWithItems.OrderItems) {
                if (item.Product2.Weight_kg__c == null ||
                    item.Product2.Length_cm__c == null ||
                    item.Product2.Width_cm__c  == null ||
                    item.Product2.Height_cm__c == null) {
                    newOrder.addError('No se puede marcar como Ready to Ship: hay productos sin dimensiones o peso definidos.');
                    break;
                }
            }
        }
    }

    /**
     * @description Evalúa de forma masiva qué Orders han cambiado su Logistics_Status__c a "Ready to Ship".
     * @param newOrders Lista de registros actualizados (Trigger.new).
     * @param oldMap    Mapa con el estado anterior de cada registro (Trigger.oldMap).
     */
    public static void processReadyToShip(
        List<Order> newOrders,
        Map<Id, Order> oldMap
    ) {
        // Una única llamada asíncrona para toda la transacción — bulkificado
        Set<Id> orderIdsToProcess = getOrdersChangingToReadyToShip(newOrders, oldMap);

        if (!orderIdsToProcess.isEmpty()) {
            System.enqueueJob(new ShippoQueueable(orderIdsToProcess));
        }
    }
}