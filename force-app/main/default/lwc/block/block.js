import { LightningElement, api } from 'lwc';

export default class Block extends LightningElement {
    @api key;
    @api block;

    get isValid() {
        return this.block.Status__c === 'Valid';
    }

    get isInvalid() {
        return this.block.Status__c === 'Invalid';
    }

    get isEven() {
        return this.block.Index__c % 2;
    }

    handleShowModal() {
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleCloseModal() {
        const modal = this.template.querySelector('c-modal');
        modal.hide();
    }
}