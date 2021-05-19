public with sharing class ContactHandler {
    private String EDIT_ACCESS_LEVEL = 'Edit', DELIMITER = ': ',
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

}
