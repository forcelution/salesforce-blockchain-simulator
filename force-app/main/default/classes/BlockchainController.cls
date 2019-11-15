public with sharing class BlockchainController {

    @AuraEnabled(cacheable=true)
    public static List<Block__c> getBlocks(Id blockchainId){
        return [SELECT Id, Name, Index__c, Timestamp__c, Previous_Hash__c, Hash__c, Nonce__c, Number_of_Transactions__c, Status__c,
                (SELECT Id, From_Participant__c, From_Participant_Name__c, To_Participant__c, To_Participant_Name__c, Amount__c, Type__c, CreatedDate
                 FROM Transactions__r ORDER BY Id)
                FROM Block__c WHERE Blockchain__c = :blockchainId ORDER BY Index__c Asc];
    }
    
    @AuraEnabled
    public static void createGenesisBlock(Id blockchainId){
        Blockchain__c blockchain = getBlockchain(blockchainId);
        Block genesisBlock = new Block();
        genesisBlock.mineHash(Integer.valueOf(blockchain.Difficulty__c));
        genesisBlock.addToBlockchain(blockchainId);
    }

    @AuraEnabled
    public static BlockWithTransactions addBlock(Id blockchainId, Id minerId){
        Blockchain__c blockchain = getBlockchain(blockchainId);
        Block__c previousBlock = blockchain.Blocks__r[0];
        List<Transaction__c> pendingTransactions = blockchain.Transactions__r;
        
        Block block = new Block();
        block.index = previousBlock.Index__c.intValue() + 1;
        block.previousHash = previousBlock.Hash__c;
        block.setTransactionData(pendingTransactions);
        
        block.mineHash(Integer.valueOf(blockchain.Difficulty__c));
        Block__c addedBlock = block.addToBlockchain(blockchainId);
        commitTransactions(pendingTransactions, addedBlock.Id);
        rewardMiner(minerId, blockchain.Reward__c, blockchainId);
        return new BlockWithTransactions(addedBlock, pendingTransactions);
    }

    @AuraEnabled
    public static List<BlockValidationResult> validateBlockchain(Id blockchainId){
        List<BlockValidationResult> result = new List<BlockValidationResult>();
        List<Block__c> chain = getBlocks(blockchainId);
        String recalculatedHash = chain[0].Hash__c;
        for (integer i=1; i<chain.size(); i++){
            Block__c currentBlock = chain[i];

            // Recalculate the hash and validate if it matches the stored hash:
            Block block = new Block();
            block.timestamp = currentBlock.Timestamp__c;
            block.previousHash = recalculatedHash;
            block.nonce = currentBlock.Nonce__c.intValue();
            block.setTransactionData(currentBlock.Transactions__r);
            recalculatedHash = block.calculateHash();
            BlockValidationResult blockResult = new BlockValidationResult(currentBlock.Name, currentBlock.Hash__c, recalculatedHash);
            currentBlock.Status__c = blockResult.isValid ? 'Valid' : 'Invalid';
            result.add(blockResult);
        }
        Update chain;
        return result;
    }

    private static Blockchain__c getBlockchain(Id blockchainId){
        return [SELECT Id, Difficulty__c, Reward__c,
                (SELECT Index__c, Hash__c FROM Blocks__r ORDER BY Index__c Desc LIMIT 1),
                (SELECT Id, From_Participant__c, From_Participant_Name__c, To_Participant__c, To_Participant_Name__c, Amount__c, Type__c, CreatedDate
                 FROM Transactions__r WHERE Status__c = 'Pending' ORDER BY Id)
                FROM Blockchain__c WHERE Id = :blockchainId];
    }

    private static void commitTransactions(List<Transaction__c> transactions, Id blockId){
        Map<Id,Double[]> participantsAmounts = new Map<Id,Double[]>(); // Participant IDs with total amount sent and total amount received
        for (Transaction__c trans : transactions){
            
            // Update the amounts of the sending participant and the receiving participant:
            if (trans.From_Participant__c != null){
                if (participantsAmounts.containsKey(trans.From_Participant__c))
                    participantsAmounts.get(trans.From_Participant__c)[0] += trans.Amount__c;
                else
                    participantsAmounts.put(trans.From_Participant__c, new Double[]{trans.Amount__c,0});
            }
            if (trans.To_Participant__c != null){
                if (participantsAmounts.containsKey(trans.To_Participant__c))
                    participantsAmounts.get(trans.To_Participant__c)[1] += trans.Amount__c;
                else
                    participantsAmounts.put(trans.To_Participant__c, new Double[]{0,trans.Amount__c});
            }
            
            // Relate the transaction to the new block and set the transaction's status to 'Commited':
            trans.Block__c = blockId;
            trans.Status__c = 'Committed';
        }
        Update transactions;
        updateParticipantsAmounts(participantsAmounts);
    }

    private static void rewardMiner(Id minerId, Decimal rewardAmount, Id blockchainId){
        Transaction__c rewardTransaction = new Transaction__c(
            Type__c = 'Reward',
            Amount__c = rewardAmount,
            To_Participant__c = minerId,
            Blockchain__c = blockchainId,
            Status__c = 'Pending'
        );
        Insert rewardTransaction;
    }

    private static void updateParticipantsAmounts(Map<Id,Double[]> participantsAmounts){
        List<Participant__c> participants = [SELECT Id, Total_Amount_Sent__c, Total_Amount_Received__c FROM Participant__c WHERE Id IN :participantsAmounts.keySet()];
        for (Participant__c participant : participants){
            participant.Total_Amount_Sent__c += participantsAmounts.get(participant.Id)[0];
            participant.Total_Amount_Received__c += participantsAmounts.get(participant.Id)[1];
        }
        Update participants;
    }

    public class BlockWithTransactions {
        @AuraEnabled public Block__c block { get; private set; }
        @AuraEnabled public List<Transaction__c> transactions { get; private set; }

        public BlockWithTransactions(Block__c block, List<Transaction__c> transactions){
            this.block = block;
            this.transactions = transactions;
        }
    }

    public class BlockValidationResult {
        @AuraEnabled public String blockName { get; private set; }
        @AuraEnabled public String storedHash { get; private set; }
        @AuraEnabled public String recalculatedHash { get; private set; }
        @AuraEnabled public Boolean isValid { get; private set; }
        @AuraEnabled public String statusIcon { get; private set; }

        public BlockValidationResult(String blockName, String storedHash, String recalculatedHash) {
            this.blockName = blockName;
            this.storedHash = storedHash;
            this.recalculatedHash = recalculatedHash;
            this.isValid = storedHash == recalculatedHash;
            if (isValid)
                statusIcon = 'action:approval';
            else
                statusIcon = 'action:close';
        }
    }
    
}