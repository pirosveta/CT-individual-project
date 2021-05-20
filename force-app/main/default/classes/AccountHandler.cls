public with sharing class AccountHandler {
    private String EDIT_ACCESS_LEVEL = 'Edit', NONE_ACCESS_LEVEL = 'None', DELIMITER = ': ',
        IS_INSERT = 'isInsert', IS_UPDATE = 'isUpdate', IS_DELETE = 'isDelete',
        FOLLOWING_ERROR = 'The following error has occurred.', 
        AFFECTED_FIELDS = 'Account fields that affected this error: ';

    private ContactHandler contactHandler = new ContactHandler();

    public void insertOp(Id user, List<Territory__c> hierarchy) {
        List<AccountShare> newShares = new List<AccountShare>();
        List<Account> accs = [SELECT Id, Name FROM Account WHERE Territory__c IN :hierarchy];
        contactHandler.insertOp(user, accs);
        for (Account acc : accs) {
            AccountShare accShare = new AccountShare();
            accShare.AccountId = acc.Id;
            accShare.UserOrGroupId = user;
            accShare.AccountAccessLevel = EDIT_ACCESS_LEVEL;
            accShare.OpportunityAccessLevel = NONE_ACCESS_LEVEL;
            accShare.ContactAccessLevel = NONE_ACCESS_LEVEL;
            accShare.CaseAccessLevel = NONE_ACCESS_LEVEL;
            newShares.add(accShare);
        }
        List<Database.SaveResult> srs = Database.insert(newShares, false);
        for (Database.SaveResult sr : srs) {
            for(Database.Error err : sr.getErrors()) {
                System.debug(FOLLOWING_ERROR);                    
                System.debug(err.getStatusCode() + DELIMITER + err.getMessage());
                System.debug(AFFECTED_FIELDS + err.getFields());
            }
        }
    }

    public void deleteOp(Id user, List<Territory__c> hierarchy) {
        List<Account> accs = [SELECT Id FROM Account WHERE Territory__c IN :hierarchy];
        List<Id> accsId = new List<Id>();
        for (Account acc : accs) {
            accsId.add(acc.Id);
        }
        contactHandler.deleteOp(user, accs);
        List<AccountShare> oldShares = [SELECT Id FROM AccountShare WHERE AccountId IN :accsId];
        Database.delete(oldShares, false);
    }

    public void updateShares(List<Account> newAccs, Map<Id, Account> oldAccs, String operation) {
        TerritoryHandler territoryHandler = new TerritoryHandler();
        List<AccountShare> newShares = new List<AccountShare>();
        List<Id> delAccs = new List<Id>();
        List<Id> delUsers = new List<Id>();
        Map<Id, Territory__c> exTerrs = new Map<Id, Territory__c>();
        List<TerritoryUser__c> terrUsers = [SELECT User__c, Territory__c FROM TerritoryUser__c]; 

        for (Territory__c terr : [SELECT Id, Name, Nesting__c, Territory__c, Type__c FROM Territory__c]) {
            exTerrs.put(terr.Id, terr);
        }

        for (Account acc : newAccs) {
            for (TerritoryUser__c terrUser : terrUsers) {
                if (operation == IS_UPDATE) {
                    Account oldAcc = oldAccs.get(acc.Id);
                    if (terrUser.Territory__c == oldAcc.Territory__c
                    || (oldAcc.Territory__c != null
                        && territoryHandler.checkBelonging(exTerrs.get(terrUser.Territory__c), exTerrs.get(oldAcc.Territory__c)))) {
                        delAccs.add(oldAcc.Id);
                        delUsers.add(terrUser.User__c);
                    }
                }
                if (terrUser.Territory__c == acc.Territory__c
                    || (acc.Territory__c != null
                        && territoryHandler.checkBelonging(exTerrs.get(terrUser.Territory__c), exTerrs.get(acc.Territory__c)))) {
                    if (operation == IS_INSERT || operation == IS_UPDATE) {
                        AccountShare accShare = new AccountShare();
                        accShare.AccountId = acc.Id;
                        accShare.UserOrGroupId = terrUser.User__c;
                        accShare.AccountAccessLevel = EDIT_ACCESS_LEVEL;
                        accShare.OpportunityAccessLevel = NONE_ACCESS_LEVEL;
                        accShare.ContactAccessLevel = NONE_ACCESS_LEVEL;
                        accShare.CaseAccessLevel = NONE_ACCESS_LEVEL;
                        newShares.add(accShare);
                    }
                    else if (operation == IS_DELETE) {
                        delAccs.add(acc.Id);
                        delUsers.add(terrUser.User__c);
                    }
                }
            }
        }
        Database.insert(newShares, false);
        List<AccountShare> delShares = [SELECT Id FROM AccountShare 
                                        WHERE AccountId IN :delAccs AND UserOrGroupId IN :delUsers];
        Database.delete(delShares);
    }

}
