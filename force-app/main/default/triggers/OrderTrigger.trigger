/**
 * @description Trigger principal para el objeto Order.
 * @author: Alejo De Urrengoechea 
 */
 
trigger OrderTrigger on Order (before update, after update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        OrderTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        OrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}