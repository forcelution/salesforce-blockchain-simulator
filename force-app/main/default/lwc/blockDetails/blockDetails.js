import { LightningElement, api, track } from 'lwc';

const columns = [
    { label: 'Type', fieldName: 'Type__c', initialWidth: 90 },
    { label: 'From', fieldName: 'From_Participant_Name__c' },
    { label: 'To', fieldName: 'To_Participant_Name__c' },
    { label: 'Amount', fieldName: 'Amount__c', type: 'number', initialWidth: 90 },
    { label: 'Date', fieldName: 'CreatedDate', type: 'date', initialWidth: 140, typeAttributes: {
        year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }
    }
];

export default class blockDetails extends LightningElement {
    @api blockId;
    @api transactions;
    @track columns = columns;
}