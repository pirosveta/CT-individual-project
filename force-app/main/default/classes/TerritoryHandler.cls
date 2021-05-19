public with sharing class TerritoryHandler {
    private String ERROR_MESSAGE = 'A territory with such parameters already exist!', 
        IS_INSERT = 'isInsert', IS_UPDATE = 'isUpdate', IS_DELETE = 'isDelete';
    private Decimal NESTING_UNIT = 1;
    
    private AccountHandler accountHandler = new AccountHandler();

    private List<Territory__c> getTerritories(Territory__c terr) {
        return [SELECT Id, Name, Nesting__c, Type__c, Territory__c FROM Territory__c 
                WHERE Territory__c=:terr.Id]; 
    }

    private List<Territory__c> getChildTerritories(Territory__c terr, Territory__c stopTerr) {
        List<Territory__c> children = new List<Territory__c>();
        children.add(terr); 
        for (Territory__c childTerr : getTerritories(terr)) {
            if (childTerr != stopTerr) {
                children.addAll(getChildTerritories(childTerr, null));
            }
        }
        return children;
    }

    public Boolean checkBelonging(Territory__c highTerr, Territory__c lowTerr) {
        for (Territory__c terr : getTerritories(highTerr)) {
            if (terr.Id != lowTerr.Id) {
                if (checkBelonging(terr, lowTerr)) {
                    return true;
                }
            }
            else {
                return true;
            }
        }
        return false;
    }

    public List<Territory__c> checkDuplication(List<Territory__c> terrs) {
        List<String> name = new List<String>();
        List<Decimal> nesting = new List<Decimal>();
        List<String> type = new List<String>();
        List<Territory__c> errTerr = new List<Territory__c>();

        for (Territory__c terr : terrs) {
            name.add(terr.Name);
            nesting.add(terr.Nesting__c);
            type.add(terr.Type__c);
        }

        List<Territory__c> exTerrs = [SELECT Id, Name, Nesting__c, Type__c FROM Territory__c 
                                   WHERE Name IN :name AND Nesting__c IN :nesting AND Type__c IN :type];
        for (Territory__c terr : terrs) {
            for (Territory__c exTerr : exTerrs) {
                if (terr.name == exTerr.name 
                    && terr.Nesting__c == exTerr.Nesting__c 
                    && terr.Type__c == exTerr.Type__c
                    && terr.Id != exTerr.Id) {
                    errTerr.add(terr);
                }
            }
        }
        return errTerr;
    }

    public void reassignTerritories(Territory__c terr) {
        for (Territory__c child : getTerritories(terr)) {
            child.Nesting__c = terr.Nesting__c + NESTING_UNIT;
            reassignTerritories(child);
        }
    }

    public void insertOp(Id user, Territory__c terr) {
        List<Territory__c> hierarchy = getChildTerritories(terr, null);
        accountHandler.insertOp(user, hierarchy);
    }

    public void updateOp(Id user, Territory__c oldTerr, Territory__c newTerr) {
        List<Territory__c> hierarchy = new List<Territory__c>();

        if (oldTerr.Nesting__c < newTerr.Nesting__c && checkBelonging(oldTerr, newTerr)) {
            hierarchy = getChildTerritories(oldTerr, newTerr);
            accountHandler.deleteOp(user, hierarchy);
        }
        if (oldTerr.Nesting__c > newTerr.Nesting__c && checkBelonging(newTerr, oldTerr)) {
            hierarchy = getChildTerritories(newTerr, oldTerr);
            accountHandler.insertOp(user, hierarchy);
        }
        else if (oldTerr != newTerr) {
            List<Territory__c> oldHierarchy = getChildTerritories(oldTerr, oldTerr);
            accountHandler.deleteOp(user, oldHierarchy);
            hierarchy = getChildTerritories(newTerr, null);
            accountHandler.insertOp(user, hierarchy);
        }
    }

    public void deleteOp(Id user, Territory__c terr) {
        List<Territory__c> hierarchy = getChildTerritories(terr, null);
        accountHandler.deleteOp(user, hierarchy);
    }

    public void addTerritory(List<Territory__c> terrs) {
        Map<Id, Territory__c> parentTerritories = new Map<Id,Territory__c>();
        for (Territory__c terr : [SELECT Id, Nesting__c FROM Territory__c]) {
            parentTerritories.put(terr.Id, terr);

        }
        for (Territory__c terr : terrs) {
            if (terr.Territory__c != null) {
                terr.Nesting__c = parentTerritories.get(terr.Territory__c).Nesting__c + NESTING_UNIT;
            }
            else {
                terr.Nesting__c = NESTING_UNIT;
            }
        }       
        List<Territory__c> errTerr = checkDuplication(terrs);
        for (Territory__c terr : errTerr) {
            terr.addError(ERROR_MESSAGE); 
        }
    }

    public void replaceTerritory(Map<Id, Territory__c> oldTerrs, List<Territory__c> newTerrs) {
        Map<Id, Territory__c> parentTerritories = new Map<Id,Territory__c>();
        for (Territory__c terr : [SELECT Id, Nesting__c FROM Territory__c]) {
            parentTerritories.put(terr.Id, terr);

        }
        for (Territory__c terr : newTerrs) {
            if (terr.Territory__c != oldTerrs.get(terr.Id).Territory__c) {
                if (terr.Territory__c != null) {
                    terr.Nesting__c = parentTerritories.get(terr.Territory__c).Nesting__c + NESTING_UNIT;
                }
                else {
                    terr.Nesting__c = NESTING_UNIT;
                }
            }
        }
        List<Territory__c> errTerr = checkDuplication(newTerrs);
        for (Territory__c terr : errTerr) {
            terr.addError(ERROR_MESSAGE); 
        }  
        for (Territory__c terr : newTerrs) {
            if (!terr.hasErrors() 
                && terr.Nesting__c != oldTerrs.get(terr.Id).Nesting__c) {
                reassignTerritories(terr);
            }
        }
    }

    public void removeTerritory(List<Territory__c> terrs) {
        List<Id> terrIds = new List<Id>();
        for (Territory__c terr : terrs) {
            terrIds.add(terr.Id);
        }
        List<Territory__c> children = [SELECT Id FROM Territory__c WHERE Territory__c IN :terrIds];
        Database.delete(children);
    }

    public void updateHierarchy(List<Territory__c> newTerrs, Map<Id, Territory__c> oldTerrs, String operation) {
        Map<Id, Territory__c> exTerrs = new Map<Id, Territory__c>();
        List<TerritoryUser__c> terrUsers = [SELECT User__c, Territory__c FROM TerritoryUser__c]; 

        for (Territory__c terr : [SELECT Id, Name, Nesting__c, Territory__c, Type__c FROM Territory__c]) {
            exTerrs.put(terr.Id, terr);
        }

        if (operation == IS_UPDATE) {
            for (Territory__c newTerr : newTerrs) {
                Territory__c oldTerr = oldTerrs.get(newTerr.Id);
                if (oldTerr.Territory__c != newTerr.Territory__c) {
                    for (TerritoryUser__c terrUser : terrUsers) {
                        if (terrUser.Territory__c == oldTerr.Territory__c
                            || checkBelonging(exTerrs.get(terrUser.Territory__c), oldTerr)) {
                            deleteOp(terrUser.User__c, oldTerr);
                        }
                        if (terrUser.Territory__c == newTerr.Territory__c
                            || (newTerr.Territory__c != null
                                && checkBelonging(exTerrs.get(terrUser.Territory__c), exTerrs.get(newTerr.Territory__c)))) {
                            insertOp(terrUser.User__c, newTerr);
                        }
                    }
                }
            }
        }
        else {
            List<TerritoryUser__c> nonExTerrs = new List<TerritoryUser__c>();
            for (Territory__c terr : newTerrs) {
                for (TerritoryUser__c terrUser : terrUsers) {
                    if (terrUser.Territory__c == null) {
                        nonExTerrs.add(terrUser);
                    }
                    else if (checkBelonging(exTerrs.get(terrUser.Territory__c), terr)) {
                        if (operation == IS_INSERT) {
                            insertOp(terrUser.User__c, terr);
                        }
                        else if (operation == IS_DELETE) {
                            deleteOp(terrUser.User__c, terr);
                        }
                    }
                }
            }
            if (nonExTerrs.size() > 0) {
                Database.delete(nonExTerrs, false);
            }
        }
    }
}
