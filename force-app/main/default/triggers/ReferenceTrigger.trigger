trigger ReferenceTrigger on Reference__c (before insert, before update, before delete) {
    private String IS_INSERT = 'isInsert', IS_UPDATE = 'isUpdate', IS_DELETE = 'isDelete';

    ContactHandler handler = new ContactHandler();

    if (Trigger.isInsert) {
        List<Reference__c> rfrs = Trigger.new;
        handler.updateShares(rfrs, IS_INSERT); 
    }
    else if (Trigger.isUpdate) {
        List<Reference__c> oldRfrs = Trigger.old;
        List<Reference__c> newRfrs = Trigger.new;
        handler.updateShares(oldRfrs, IS_DELETE);
        handler.updateShares(newRfrs, IS_INSERT);
    }
    else if (Trigger.isDelete) {
        List<Reference__c> rfrs = Trigger.old;
        handler.updateShares(rfrs, IS_DELETE);
    }
}