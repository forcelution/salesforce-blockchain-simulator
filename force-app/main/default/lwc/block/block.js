import { LightningElement, api } from 'lwc';

export default class Block extends LightningElement {
    @api key;
    @api block;

    get isValid() {
        return this.block.Status__c === 'Valid' ? true : false;
    }

    get isInvalid() {
        return this.block.Status__c === 'Invalid' ? true : false;
    }
}