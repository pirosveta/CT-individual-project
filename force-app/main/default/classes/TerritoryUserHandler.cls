public with sharing class TerritoryUserHandler {
    private TerritoryHandler territoryHandler = new TerritoryHandler();

    public void insertOp(List<TerritoryUser__c> newTerrUsers) {
        Map<Id, Territory__c> territories = new Map<Id, Territory__c>();
        for(Territory__c terr : [SELECT Id, Name, Nesting__c, Territory__c, Type__c FROM Territory__c]) {
            territories.put(terr.Id, terr);
        }
        for (TerritoryUser__c terrUser : newTerrUsers) {
            Id user = terrUser.User__c;
            Territory__c terr = territories.get(terrUser.Territory__c);
            territoryHandler.insertOp(user, terr);
        }
    }

    public void updateOp(List<TerritoryUser__c> oldTerrUsers, Map<Id, TerritoryUser__c> newTerrUsers) {
        Map<Id, Territory__c> territories = new Map<Id, Territory__c>();
        for(Territory__c terr : [SELECT Id, Name, Nesting__c, Territory__c, Type__c FROM Territory__c]) {
            territories.put(terr.Id, terr);
        }
        for (TerritoryUser__c terrUser : oldTerrUsers) {
            Id user = terrUser.User__c;
            Territory__c oldTerr = territories.get(terrUser.Territory__c);
            Territory__c newTerr = territories.get(newTerrUsers.get(terrUser.Id).Territory__c);
            territoryHandler.updateOp(user, oldTerr, newTerr);
        }
    }

    public void deleteOp(List<TerritoryUser__c> oldTerrUsers) {
        Map<Id, Territory__c> territories = new Map<Id, Territory__c>();
        for(Territory__c terr : [SELECT Id, Name, Nesting__c, Territory__c, Type__c FROM Territory__c]) {
            territories.put(terr.Id, terr);
        }
        for (TerritoryUser__c terrUser : oldTerrUsers) {
            Id user = terrUser.User__c;
            Territory__c terr = territories.get(terrUser.Territory__c);
            territoryHandler.deleteOp(user, terr);
        }
    }

}
