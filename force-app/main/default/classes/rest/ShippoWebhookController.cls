/**
 * @description Endpoint REST que recibe los webhooks de tracking de Shippo.
 * @author Alejo De Urrengoechea
 */
@RestResource(urlMapping='/shippo/webhook/*')
global with sharing class ShippoWebhookController {

    /**
     * @description Recibe el HTTP POST de Shippo con el evento de tracking.
     */
    @HttpPost
    global static void handleTrackingWebhook() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String body = req.requestBody.toString();
            Map<String, Object> payload =
                (Map<String, Object>) JSON.deserializeUntyped(body);

            Map<String, Object> trackingData =
                (Map<String, Object>) payload.get('data');

            if (trackingData == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"error": "Missing data field"}');
                return;
            }

            String trackingNumber = (String) trackingData.get('tracking_number');
            Map<String, Object> trackingStatus =
                (Map<String, Object>) trackingData.get('tracking_status');

            if (trackingNumber == null || trackingStatus == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"error": "Missing tracking_number or tracking_status"}');
                return;
            }

            String statusCode = (String) trackingStatus.get('status');
            String statusDate = (String) trackingStatus.get('status_date');

            ShippoWebhookService.processTrackingEvent(
                trackingNumber,
                statusCode,
                statusDate
            );

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"success": true}');

        } catch (Exception e) {
            System.debug('ERROR en webhook Shippo: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error": "' + e.getMessage() + '"}');
        }
    }
}