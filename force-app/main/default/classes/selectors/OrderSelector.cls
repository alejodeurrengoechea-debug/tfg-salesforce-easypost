/**
 * @description Clase Selectora que centraliza todas las consultas SOQL del objeto Order.
 * @author Alejo De Urrengoechea
 */
public with sharing class OrderSelector {

    /**
     * @description Obtiene los Orders con todos los datos necesarios para construir el payload de Shippo.
     * @param orderIds Set de Ids de Orders a consultar.
     * @return Lista de Orders con sus relaciones precargadas, o lista vacía si no hay acceso.
     */
    public static List<Order> getOrdersForShippo(Set<Id> orderIds) {
        if (!SObjectAccessUtil.isAccessible(Order.SObjectType)) {
            return new List<Order>();
        }

        return [
            SELECT
                Id,
                OrderNumber,
                Logistics_Status__c,
                Ship_To_Account__c,
                Ship_To_Account__r.Name,
                Ship_To_Account__r.ShippingStreet,
                Ship_To_Account__r.ShippingCity,
                Ship_To_Account__r.ShippingState,
                Ship_To_Account__r.ShippingPostalCode,
                Ship_To_Account__r.ShippingCountry,
                (
                    SELECT
                        Id,
                        Quantity,
                        Product2Id,
                        Product2.Name,
                        Product2.Weight_kg__c,
                        Product2.Length_cm__c,
                        Product2.Width_cm__c,
                        Product2.Height_cm__c,
                        Product2.Is_Fragile__c
                    FROM OrderItems
                )
            FROM Order
            WHERE Id IN :orderIds
        ];
    }

    /**
     * @description Obtiene los Orders con sus líneas de producto.
     * @param orderIds Set de Ids de Orders a consultar.
     * @return Mapa de Id → Order con sus OrderItems y datos de Product2.
     */
    public static Map<Id, Order> getOrdersWithItemsForValidation(Set<Id> orderIds) {
        if (!SObjectAccessUtil.isAccessible(Order.SObjectType)) {
            return new Map<Id, Order>();
        }

        return new Map<Id, Order>([
            SELECT Id, Ship_To_Account__c,
                (
                    SELECT Id,
                           Product2.Weight_kg__c,
                           Product2.Length_cm__c,
                           Product2.Width_cm__c,
                           Product2.Height_cm__c
                    FROM OrderItems
                )
            FROM Order
            WHERE Id IN :orderIds
        ]);
    }
}