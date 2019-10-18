import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { refreshApex } from '@salesforce/apex';
import getBlocks from '@salesforce/apex/BlockchainController.getBlocks';

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
        } else if (result.error) {
            this.error = result.error;
            this.blocks = undefined;
        }
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