import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import createGenesisBlock from '@salesforce/apex/BlockchainController.createGenesisBlock';

export default class BlockchainController extends LightningElement {
    @api recordId;
    @track result;
    @track error;

    @wire(CurrentPageReference) pageRef;

    handleInitializeBlockchain(){
        createGenesisBlock({ blockchainId: this.recordId })
            .then(result => {
                this.result = result;
                this.error = undefined;
                fireEvent(this.pageRef, 'refreshBlockchain', '');
            })
            .catch(error => {
                this.error = error;
            })
    }

    handleAddBlock(){
        fireEvent(this.pageRef, 'refreshBlockchain', '');
    }

}