import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { showToast } from 'c/toast';
import { refreshApex } from '@salesforce/apex';
import getBlocks from '@salesforce/apex/BlockchainController.getBlocks';
import createGenesisBlock from '@salesforce/apex/BlockchainController.createGenesisBlock';

export default class Blockchain extends LightningElement {
    @api recordId;
    @track blocks;
    @track error;
    wiredBlocks;

    @wire(CurrentPageReference) pageRef;

    @wire(getBlocks, { blockchainId: '$recordId' })
    wiredCallback(result) {
        this.wiredBlocks = result;
        if (result.data) {
            this.blocks = result.data;
            this.error = undefined;
            if (this.blocks.length === 0) {
                this.initializeBlockchain();
            }
        } else if (result.error) {
            this.error = result.error;
            this.blocks = undefined;
        }
    }

    initializeBlockchain() {
        showToast('info','Initializing blockchain.');
        createGenesisBlock({ blockchainId: this.recordId })
            .then(() => {
                this.refresh();
                showToast('success','Genesis block created.');
            })
            .catch(error => {
                this.error = error;
            })
    }
    
    get isInitialized() {
        return this.blocks && this.blocks.length > 0;
    }

    refresh() {
        return refreshApex(this.wiredBlocks);
    }

    connectedCallback() {
        registerListener('refreshBlockchain', this.refresh, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }
}