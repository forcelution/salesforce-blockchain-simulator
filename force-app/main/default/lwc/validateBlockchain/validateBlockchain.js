import { LightningElement, api, track, wire } from 'lwc';
import validateBlockchain from '@salesforce/apex/BlockchainController.validateBlockchain';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

const columns = [
    { label: 'Block', fieldName: 'blockName', initialWidth: 75 },
    { label: 'Stored Hash', fieldName: 'storedHash' },
    { label: 'Recalculated Hash', fieldName: 'recalculatedHash' },
    { label: 'Valid', cellAttributes: { iconName: { fieldName: 'statusIcon' }, iconPosition: 'right' }, initialWidth: 70 }
];

export default class ValidateBlockchain extends LightningElement {
    @api blockchainId;
    @track columns = columns;
    @track result;
    @track error;

    @wire(CurrentPageReference) pageRef;
    
    connectedCallback(){
        validateBlockchain({ blockchainId: this.blockchainId })
            .then(result => {
                this.result = result;
                this.error = undefined;
                fireEvent(this.pageRef, 'refreshBlockchain', '');
            })
            .catch(error => {
                this.result = undefined;
                this.error = error;
            })
    }
}