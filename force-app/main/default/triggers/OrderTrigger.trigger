/**
 * @description Trigger principal para el objeto Order.
 * @author: Alejo De Urrengoechea 
 */
 
trigger OrderTrigger on Order (after update) {

    if (Trigger.isAfter && Trigger.isUpdate) {
        OrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}