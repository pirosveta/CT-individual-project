public with sharing class ContactHandler {
    private String EDIT_ACCESS_LEVEL = 'Edit', DELIMITER = ': ', OWNER_ROW_CAUSE = 'Owner',
        IS_INSERT = 'isInsert', IS_UPDATE = 'idUpdate', IS_DELETE = 'isDelete',
        FOLLOWING_ERROR = 'The following error has occurred.',
        AFFECTED_FIELDS = 'Contact fields that affected this error: ';

    public void insertOp(Id user, List<Account> accs) {
        List<Id> cnts = new List<Id>();
        List<ContactShare> newShares = new List<ContactShare>();
        List<Reference__c> rfrs = [SELECT Contact__c FROM Reference__c WHERE Account__c IN :accs];

        for (Reference__c rfr : rfrs) {
            cnts.add(rfr.Contact__c);
        }
        for (Id cnt : cnts) {
            ContactShare cntShare = new ContactShare();
            cntShare.ContactId = cnt;
            cntShare.UserOrGroupId = user;
            cntShare.ContactAccessLevel = EDIT_ACCESS_LEVEL;
            newShares.add(cntShare);
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

    public void deleteOp(Id user, List<Account> accs) {
        List<Id> cnts = new List<Id>();
        List<Reference__c> rfrs = [SELECT Contact__c FROM Reference__c WHERE Account__c IN :accs];

        for (Reference__c rfr : rfrs) {
            cnts.add(rfr.Contact__c);
        }
        List<ContactShare> oldShares = [SELECT Id FROM ContactShare WHERE ContactId IN :cnts];
        Database.delete(oldShares, false);
    }

    public void updateShares(List<Reference__c> rfrs, String operation) {
        List<ContactShare> newShares = new List<ContactShare>();
        List<ContactShare> delShares = new List<ContactShare>();
        List<Id> accs = new List<Id>();
        List<Id> cnts = new List<Id>();
        List<Id> users = new List<Id>();

        for (Reference__c rfr : rfrs) {
            accs.add(rfr.Account__c);
            cnts.add(rfr.Contact__c);
        }
        List<AccountShare> accShares = [SELECT AccountId, UserOrGroupId FROM AccountShare 
                                        WHERE AccountId IN :accs AND RowCause!=:OWNER_ROW_CAUSE];
        if (operation == IS_INSERT) {
            for (Reference__c rfr : rfrs) {
                for (AccountShare accShare : accShares) {
                    if (rfr.Account__c == accShare.AccountId) {
                        ContactShare cntShare = new ContactShare();
                        cntShare.ContactId = rfr.Contact__c;
                        cntShare.UserOrGroupId = accShare.UserOrGroupId;
                        cntShare.ContactAccessLevel = EDIT_ACCESS_LEVEL;
                        newShares.add(cntShare);
                    }
                }
            }
        }
        else if (operation == IS_DELETE) {
            for (AccountShare accShare : accShares) {
                users.add(accShare.UserOrGroupId);
            }
            delShares = [SELECT Id FROM ContactShare 
                        WHERE ContactId IN :cnts AND UserOrGroupId IN :users];
        }
        System.debug(newShares.size());
        Database.insert(newShares);
        Database.delete(delShares);
    }

}
