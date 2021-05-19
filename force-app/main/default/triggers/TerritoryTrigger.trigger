trigger TerritoryTrigger on Territory__c (before insert, before update, before delete) {
    private String IS_INSERT = 'isInsert', IS_UPDATE = 'isUpdate', IS_DELETE = 'isDelete';

    TerritoryHandler handler = new TerritoryHandler();

    if (Trigger.isInsert) {
        List<Territory__c> terrs = Trigger.new;
        handler.addTerritory(terrs);
        handler.updateHierarchy(terrs, new Map<Id, Territory__c>(), IS_INSERT);
    }
    else if (Trigger.isUpdate) {
        Map<Id, Territory__c> oldTerrs = Trigger.oldMap;
        List<Territory__c> newTerrs = Trigger.new;
        handler.replaceTerritory(oldTerrs, newTerrs);
        handler.updateHierarchy(newTerrs, oldTerrs, IS_UPDATE);
    }
    else if (Trigger.isDelete) {
        List<Territory__c> terrs = Trigger.old;
        handler.removeTerritory(terrs);
        handler.updateHierarchy(terrs, new Map<Id,Territory__c>(), IS_DELETE);
    }
}