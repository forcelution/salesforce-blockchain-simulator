public inherited sharing class Block {
    
    public Integer index { get; set; }
    public DateTime timestamp { get; set; }
    public String previousHash { get; set; }
    public String hash { get; private set; }
    public Integer nonce { get; set; }
    public String data { get; private set; }
    public Integer numberOfTransactions { get; private set; }
    
    public Block(){
        timestamp = Datetime.now();
        index = 0;
        numberOfTransactions = 0;
        nonce = 0;
    }
    
    public String calculateHash(){
        Blob input = Blob.valueOf(timestamp + previousHash + data + nonce);
        Blob outputBytes = Crypto.generateMac('HmacSHA256', input, Blob.valueOf('key'));
        return EncodingUtil.base64Encode(outputBytes);
    }
    
    public void mineHash(Integer difficulty){
        String leadingZeros = '';
        leadingZeros = leadingZeros.rightPad(difficulty, '0');
        while (hash == null || !hash.startsWith(leadingZeros)){
            nonce++;
            hash = calculateHash();
        }
    }
    
    public Block__c addToBlockchain(Id blockchainId){
        Block__c block = new Block__c();
        block.Index__c = index;
        block.Name = 'Block ' + index;
        if (index == 0) block.Name += ' (Genesis Block)';
        block.Blockchain__c = blockchainId;
        block.Timestamp__c = timestamp;
        block.Previous_Hash__c = previousHash;
        block.Hash__c = hash;
        block.Nonce__c = nonce;
        block.Number_of_Transactions__c = numberOfTransactions;
        Insert block;
        return block;
    }

    public void setTransactionData(List<Transaction__c> transactions){
        List<Trans> transactionData = new List<Trans>();
        for (Transaction__c trans : transactions){
            transactionData.add(new Trans(trans.From_Participant__c, trans.To_Participant__c, trans.Amount__c, trans.Type__c, trans.CreatedDate));
        }
        data = JSON.serialize(transactionData);
        numberOfTransactions = transactions.size();
    }

    private class Trans {
        String senderId;
        String receiverId;
        String amount;
        String type;
        String createdDate;

        public Trans(Id senderId, Id receiverId, Decimal amount, String type, Datetime createdDate){
            this.senderId = senderId;
            this.receiverId = receiverId;
            this.amount = amount.format();
            this.type = type;
            this.createdDate = String.valueOf(createdDate);
        }
    }
    
}