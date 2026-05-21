/**
 * @description Job asíncrono que gestiona la integración completa con la API de Shippo.
 * @author Alejo De Urrengoechea
 */
public class ShippoQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> orderIds;

    public ShippoQueueable(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {

        List<Order> orders = OrderSelector.getOrdersForShippo(this.orderIds);

        if (orders == null || orders.isEmpty()) {
            return;
        }

        List<Shipment__c> shipmentsToInsert = new List<Shipment__c>();

        for (Order ord : orders) {

            if (ord.Ship_To_Account__c == null || ord.OrderItems == null || ord.OrderItems.isEmpty()) {
                continue;
            }

            ShippoDTOs.ShippoPayload payload = buildPayload(ord);
            HttpResponse response = sendToShippo(payload);

            if (response == null) {
                continue;
            }

            if (response.getStatusCode() == 201) {
                Shipment__c shipment = parseSuccessResponse(response, ord.Id);
                if (shipment != null) {
                    shipmentsToInsert.add(shipment);
                }
            } else {
                logError(ord.Id, response);
            }
        }

        if (!shipmentsToInsert.isEmpty()) {
            insert shipmentsToInsert;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────

    private ShippoDTOs.ShippoPayload buildPayload(Order ord) {

        Shippo_Config__mdt config = Shippo_Config__mdt.getInstance('Default');

        ShippoDTOs.ShippoAddress addressFrom = new ShippoDTOs.ShippoAddress(
            config.Origin_Name__c,
            config.Origin_Street__c,
            config.Origin_City__c,
            config.Origin_State__c,
            config.Origin_Zip__c,
            config.Origin_Country__c,
            config.Origin_Email__c,
            config.Origin_Phone__c
        );

        ShippoDTOs.ShippoAddress addressTo = new ShippoDTOs.ShippoAddress(
            ord.Ship_To_Account__r.Name,
            ord.Ship_To_Account__r.ShippingStreet,
            ord.Ship_To_Account__r.ShippingCity,
            ord.Ship_To_Account__r.ShippingState,
            ord.Ship_To_Account__r.ShippingPostalCode,
            ord.Ship_To_Account__r.ShippingCountry,
            '',
            ''
        );

        // Peso total = suma de (cantidad × peso unitario) de todas las líneas
        Decimal totalWeight = 0;
        OrderItem heaviestItem = ord.OrderItems[0];

        for (OrderItem item : ord.OrderItems) {
            Decimal itemWeight = (item.Product2.Weight_kg__c != null)
                ? item.Product2.Weight_kg__c * item.Quantity
                : 0;
            totalWeight += itemWeight;

            // Las dimensiones del paquete corresponden al producto más pesado
            if (item.Product2.Weight_kg__c > heaviestItem.Product2.Weight_kg__c) {
                heaviestItem = item;
            }
        }

        ShippoDTOs.ShippoParcel parcel = new ShippoDTOs.ShippoParcel(
            heaviestItem.Product2.Length_cm__c != null ? String.valueOf(heaviestItem.Product2.Length_cm__c) : '0',
            heaviestItem.Product2.Width_cm__c  != null ? String.valueOf(heaviestItem.Product2.Width_cm__c)  : '0',
            heaviestItem.Product2.Height_cm__c != null ? String.valueOf(heaviestItem.Product2.Height_cm__c) : '0',
            String.valueOf(totalWeight)
        );

        return new ShippoDTOs.ShippoPayload(addressFrom, addressTo, parcel);
    }

    private HttpResponse sendToShippo(ShippoDTOs.ShippoPayload payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Shippo_API/shipments');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        try {
            return new Http().send(req);
        } catch (Exception e) {
            System.debug('ERROR en callout /shipments: ' + e.getMessage());
            return null;
        }
    }

    private Shipment__c parseSuccessResponse(HttpResponse response, Id orderId) {
        try {
            Map<String, Object> responseBody =
                (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            List<Object> rates = (List<Object>) responseBody.get('rates');
            if (rates == null || rates.isEmpty()) {
                System.debug('ERROR: Shippo no devolvió tarifas para Order ' + orderId);
                return null;
            }

            // Seleccionamos la tarifa marcada como CHEAPEST por Shippo
            String selectedRateId = null;
            String carrier        = null;

            for (Object rateObj : rates) {
                Map<String, Object> rate = (Map<String, Object>) rateObj;
                List<Object> attributes  = (List<Object>) rate.get('attributes');
                if (attributes != null && attributes.contains('CHEAPEST')) {
                    selectedRateId = (String) rate.get('object_id');
                    carrier        = (String) rate.get('provider');
                    break;
                }
            }

            // Si no hay tarifa CHEAPEST tomamos la primera disponible
            if (selectedRateId == null) {
                Map<String, Object> firstRate = (Map<String, Object>) rates[0];
                selectedRateId = (String) firstRate.get('object_id');
                carrier        = (String) firstRate.get('provider');
            }

            // Segundo callout: compramos la tarifa para obtener tracking + label
            HttpResponse transactionResponse = purchaseLabel(selectedRateId);

            if (transactionResponse == null || transactionResponse.getStatusCode() != 201) {
                System.debug('ERROR en /transactions para Order ' + orderId +
                    ' | Status: ' + (transactionResponse != null ? transactionResponse.getStatusCode() : 0) +
                    ' | Body: '   + (transactionResponse != null ? transactionResponse.getBody() : 'null'));
                return null;
            }

            Map<String, Object> transactionBody =
                (Map<String, Object>) JSON.deserializeUntyped(transactionResponse.getBody());

            return new Shipment__c(
                Order__c           = orderId,
                Tracking_Number__c = (String) transactionBody.get('tracking_number'),
                Carrier__c         = carrier,
                Label_URL__c       = (String) transactionBody.get('label_url')
            );

        } catch (Exception e) {
            System.debug('ERROR parseando respuesta Shippo: ' + e.getMessage());
            return null;
        }
    }

    private HttpResponse purchaseLabel(String rateId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Shippo_API/transactions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(ShippoDTOs.buildTransactionJSON(rateId));

        try {
            return new Http().send(req);
        } catch (Exception e) {
            System.debug('ERROR en callout /transactions: ' + e.getMessage());
            return null;
        }
    }

    private void logError(Id orderId, HttpResponse response) {
        System.debug(
            'ERROR Shippo para Order ' + orderId +
            ' | Status: ' + response.getStatusCode() +
            ' | Body: '   + response.getBody()
        );
    }
}