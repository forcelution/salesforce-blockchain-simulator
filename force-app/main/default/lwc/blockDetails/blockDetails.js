import { LightningElement, api, track } from 'lwc';

const transactionColumns = [
    { label: 'Type', fieldName: 'blckchn__Type__c', initialWidth: 90 },
    { label: 'From', fieldName: 'blckchn__From_Participant_Name__c' },
    { label: 'To', fieldName: 'blckchn__To_Participant_Name__c' },
    { label: 'Amount', fieldName: 'blckchn__Amount__c', type: 'number', initialWidth: 90 },
    { label: 'Date', fieldName: 'CreatedDate', type: 'date', initialWidth: 140, typeAttributes: {
        year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }
    }
];

export default class blockDetails extends LightningElement {
    @api block;
    @api transactions = [];
    @track hash;
    @track nonce;
    @track transactionColumns = transactionColumns;

    get getTransactions() {
        return this.transactions.length > 0 ? this.transactions : this.block.blckchn__Transactions__r;
    }

    @api simulateHashMining() {
        this.nonce = 0;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        let i = setInterval(() => {
            this.nonce++;
            this.hash = this.generateRandomHash();
            if (this.nonce === this.block.blckchn__Nonce__c){
                clearInterval(i);
                this.hash = this.block.blckchn__Hash__c;
            }
        }, 10);
    }

    generateRandomHash() {
        let result           = '';
        let characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        let charactersLength = characters.length;
        let i;
        for ( i = 0; i < 43; i++ ) {
           result += characters.charAt(Math.floor(Math.random() * charactersLength));
        }
        result += '=';
        return result;
     }
}