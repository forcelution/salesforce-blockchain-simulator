@isTest
private class BlockchainControllerTest {
    
    @isTest
    static void testBlockchain(){
        // Create a blockchain for digicoins:
        Blockchain__c digicoin = new Blockchain__c();
        digicoin.Name = 'Digicoin';
        digicoin.Difficulty__c = '1';
        digicoin.Reward__c = 2;
        Insert digicoin;
        
        // Add participants:
        Participant__c marc = new Participant__c(Blockchain__c = digicoin.Id, Name = 'Marc Benioff');
        Participant__c elon = new Participant__c(Blockchain__c = digicoin.Id, Name = 'Elon Musk');
        Participant__c tim  = new Participant__c(Blockchain__c = digicoin.Id, Name = 'Tim Cook');
        Insert new List<Participant__c>{marc, elon, tim};
        
        // Create the Genesis block:
        BlockchainController.createGenesisBlock(digicoin.Id);
        List<Block__c> blocks = BlockchainController.getBlocks(digicoin.Id);
        System.assertEquals('Block 0 (Genesis Block)', blocks[0].Name);
        
        // Execute some transactions:
        Double fromMarcToElon = 10;
        Double fromElonToTim = 4;
        Transaction__c trans1 = new Transaction__c(Blockchain__c = digicoin.Id, From_Participant__c = marc.Id, To_Participant__c = elon.Id, Amount__c = fromMarcToElon/2);
        Transaction__c trans2 = new Transaction__c(Blockchain__c = digicoin.Id, From_Participant__c = marc.Id, To_Participant__c = elon.Id, Amount__c = fromMarcToElon/2);
        Transaction__c trans3 = new Transaction__c(Blockchain__c = digicoin.Id, From_Participant__c = elon.Id, To_Participant__c = tim.Id, Amount__c = fromElonToTim);
        Insert new List<Transaction__c>{trans1, trans2, trans3};
        
        // Add/mine a block:
        BlockchainController.addBlock(digicoin.Id, marc.Id);
        
        // Validate that the block has been added to the blockchain:
        blocks = BlockchainController.getBlocks(digicoin.Id);
        System.assertEquals(2, blocks.size());
        Block__c block1 = blocks[1];
        System.assertNotEquals(null, block1.Hash__c);
        System.assertEquals(3, block1.Number_of_Transactions__c);
        
        // Validate that the status of the two transfer transactions is updated to 'Committed'
        // and that a pending reward transaction is created for Marc Benioff:
        List<Transaction__c> transactions = getTransactions();
        System.assertEquals(4, transactions.size());
        for (Transaction__c trans : transactions){
            if (trans.To_Participant__c == elon.Id){
                System.assertEquals('Transfer', trans.Type__c);
                System.assertEquals('Committed', trans.Status__c);
            }
            else if (trans.To_Participant__c == tim.Id){
                System.assertEquals('Transfer', trans.Type__c);
                System.assertEquals('Committed', trans.Status__c);
            }
            else {
                System.assertEquals(marc.Id, trans.To_Participant__c);
                System.assertEquals('Reward', trans.Type__c);
                System.assertEquals('Pending', trans.Status__c);
            }
        }
        
        // Validate that the balance of the participants is updated:
        for (Participant__c participant : getParticipants()){
            switch on participant.Name {
                when 'Marc Benioff' {
                    System.assertEquals(-fromMarcToElon, participant.Balance__c);
                }
                when 'Elon Musk' {
                    System.assertEquals(fromMarcToElon-fromElonToTim, participant.Balance__c);
                }
                when 'Tim Cook' {
                    System.assertEquals(fromElonToTim, participant.Balance__c);
                }
            }
        }
        
        // Check that the blockchain has not been tempered or hacked:
        List<BlockchainController.BlockValidationResult> resultList = BlockchainController.validateBlockchain(digicoin.Id);
        for (BlockchainController.BlockValidationResult result : resultList){
            System.assert(result.isValid);
        }
        
        // Change the amount of an existing transaction:
        trans1.Amount__c += 0.1;
        Update trans1;
        
        // Validate that this hack is reflected in the blockchain:
        resultList = BlockchainController.validateBlockchain(digicoin.Id);
        for (BlockchainController.BlockValidationResult result : resultList){
            System.assert(!result.isValid);
        }
    }
    
    static List<Transaction__c> getTransactions(){
        return [SELECT Id, Type__c, Status__c, From_Participant__c, To_Participant__c FROM Transaction__c];
    }
    
    static List<Participant__c> getParticipants(){
        return [SELECT Id, Name, Balance__c FROM Participant__c];
    }
}