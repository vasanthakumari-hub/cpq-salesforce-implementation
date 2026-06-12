import { LightningElement, api, wire, track } from 'lwc';
import getPaymentsByLoanId from '@salesforce/apex/LoanService.getPaymentsByLoanId';
import createPayment from '@salesforce/apex/LoanService.createPayment';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LoanPaymentManager extends LightningElement {
    @api recordId;
    @track payments;
    @track amount = 0;
    wiredPaymentsResult;

    @wire(getPaymentsByLoanId, { loanId: '$recordId' })
    wiredPayments(result) {
        this.wiredPaymentsResult = result;
        if (result.data) {
            this.payments = result.data;
        }
    }

    handleAmountChange(event) {
        this.amount = event.target.value;
    }

    handlePayment() {
        createPayment({ loanId: this.recordId, amount: this.amount })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Payment Recorded',
                    variant: 'success'
                }));
                return refreshApex(this.wiredPaymentsResult);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }
}