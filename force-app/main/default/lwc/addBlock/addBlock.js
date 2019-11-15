import { LightningElement, api, track, wire } from 'lwc';
import addBlock from '@salesforce/apex/BlockchainController.addBlock';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import { showToast } from 'c/toast';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import MINER_NAME from '@salesforce/schema/Participant__c.Name';
import BLOCKCHAIN_NAME from '@salesforce/schema/Blockchain__c.Name';
import BLOCKCHAIN_REWARD from '@salesforce/schema/Blockchain__c.Reward__c';

export default class AddBlock extends LightningElement {
    @api blockchainId;
    @api minerId;
    @track block;
    @track transactions;
    @track error;

    @wire(CurrentPageReference) pageRef;

    @track steps = [
        { number: 0, description: 'Initializing new block' },
        { number: 1, description: 'Validating transactions' },
        { number: 2, description: 'Mining hash' },
        { number: 3, description: 'Adding block to blockchain' },
        { number: 4, description: 'Creating reward transaction' },
        { number: 5, description: 'Distributing blockchain' }
    ];

    @wire(getRecord, { recordId: '$minerId', fields: [MINER_NAME] })
    miner
    get minerName() {
        return getFieldValue(this.miner.data, MINER_NAME);
    }

    @wire(getRecord, { recordId: '$blockchainId', fields: [BLOCKCHAIN_NAME, BLOCKCHAIN_REWARD] })
    blockchain
    get reward() {
        return getFieldValue(this.blockchain.data, BLOCKCHAIN_REWARD);
    }
    get rewardUnitName() {
        let name = 'reward unit';
        let blockchainName = getFieldValue(this.blockchain.data, BLOCKCHAIN_NAME);
        if (blockchainName.endsWith('coin')){
            name = blockchainName;
        }
        if (this.reward > 1) {
            name += 's';
        }
        return name;
    }

    connectedCallback() {
        this.initSteps();
        addBlock({ blockchainId: this.blockchainId, minerId: this.minerId })
            .then(result => {
                this.block = result.block;
                this.transactions = result.transactions;
                this.error = undefined;
            })
            .then(() => this.processStep(0, 0, 'Previous hash: ' + this.block.Previous_Hash__c))
            .then(() => this.processStep(1, 1000, this.block.Number_of_Transactions__c + ' valid transaction(s)'))
            .then(() => this.template.querySelector("c-block-details").simulateHashMining())
            .then(() => this.processStep(2, this.block.Nonce__c * 10, 'Hash: ' + this.block.Hash__c))
            .then(() => this.processStep(3, 1000, ''))
            .then(() => fireEvent(this.pageRef, 'refreshBlockchain', ''))
            .then(() => this.processStep(4, 1000, this.minerName + ' rewarded with ' + this.reward + ' ' + this.rewardUnitName))
            //.then(this.steps[5].show = true)
            .then(() => showToast('success', 'Process completed. New block successfully added to blockchain!'))
            .catch(error => {
                this.block = undefined;
                this.error = error;
            })
    }

    initSteps() {
        this.steps.forEach(step => {
            step.show = false;
            step.completed = false;
            step.comments = '';
        });
        this.steps[0].show = true;
    }

    processStep(number, processingTime, comments) {
        this.steps[number].show = true;
        return new Promise(resolve => {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout( () => {
                this.steps[number].completed = true;
                this.steps[number].comments = comments;
                resolve();
            },
            processingTime);
        })
    }

}