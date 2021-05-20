trigger AccountTrigger on Account (after insert, before update, before delete) {
    private String IS_INSERT = 'isInsert', IS_UPDATE = 'isUpdate', IS_DELETE = 'isDelete';

    AccountHandler handler = new AccountHandler();

    if (Trigger.isInsert) {
        List<Account> accs = Trigger.new;
        handler.updateShares(accs, new Map<Id, Account>(), IS_INSERT);
    }
    else if (Trigger.isUpdate) {
        Map<Id, Account> oldAccs = Trigger.oldMap;
        List<Account> newAccs = Trigger.new;
        handler.updateShares(newAccs, oldAccs, IS_UPDATE);
    }
    else if (Trigger.isDelete) {
        List<Account> accs = Trigger.old;
        handler.updateShares(accs, new Map<Id, Account>(), IS_DELETE);
    }
}