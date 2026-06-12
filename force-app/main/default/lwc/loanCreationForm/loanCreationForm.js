import { LightningElement, track } from 'lwc';
import createLoanApplication from '@salesforce/apex/LoanService.createLoanApplication';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LoanCreationForm extends LightningElement {
    @track amount = 0;
    @track status = 'Draft';

    get statusOptions() {
        return [
            { label: 'Draft', value: 'Draft' },
            { label: 'Under Review', value: 'Under Review' }
        ];
    }

    handleAmountChange(event) {
        this.amount = event.target.value;
    }

    handleStatusChange(event) {
        this.status = event.target.value;
    }

    async handleSubmit() {
        try {
            const result = await createLoanApplication({ amount: this.amount, status: this.status });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Loan Application Created: ' + result,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }
}
