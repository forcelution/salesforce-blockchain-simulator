import { LightningElement, api } from 'lwc';

export default class Block extends LightningElement {
    @api key;
    @api block;

    get isValid() {
        return this.block.blckchn__Status__c === 'Valid';
    }

    get isInvalid() {
        return this.block.blckchn__Status__c === 'Invalid';
    }

    get isEven() {
        return this.block.blckchn__Index__c % 2;
    }

    handleShowBlockDetails() {
        const modal = this.template.querySelector('c-modal');
        modal.show();
        const blockDetails = this.template.querySelector("c-block-details");
        blockDetails.simulateHashMining();
    }

    handleCloseBlockDetails() {
        const modal = this.template.querySelector('c-modal');
        modal.hide();
    }
}