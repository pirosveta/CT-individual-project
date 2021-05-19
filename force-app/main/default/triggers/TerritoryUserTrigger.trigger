trigger TerritoryUserTrigger on TerritoryUser__c (before insert, before update, before delete) {
    TerritoryUserHandler handler = new TerritoryUserHandler();
    
    if (Trigger.isInsert) {
        List<TerritoryUser__c> newUsers = Trigger.new;
        handler.insertOp(newUsers);
    }
    else if (Trigger.isUpdate) {
        List<TerritoryUser__c> oldUsers = Trigger.old;
        Map<Id, TerritoryUser__c> newUsers = Trigger.newMap;
        handler.updateOp(oldUsers, newUsers);
    }
    else if (Trigger.isDelete) {
        List<TerritoryUser__c> oldUsers = Trigger.old;
        handler.deleteOp(oldUsers);
    }
}