import { createElement } from 'lwc';
import LoanCalculator from 'c/loanCalculator';

describe('c-loan-calculator', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders and calculates loan preview on input change', () => {
        const element = createElement('c-loan-calculator', {
            is: LoanCalculator
        });
        document.body.appendChild(element);

        // Find input elements
        const amountInput = element.shadowRoot.querySelector('lightning-input[data-id="amount"]');
        amountInput.value = 10000;
        amountInput.dispatchEvent(new CustomEvent('change'));

        const termInput = element.shadowRoot.querySelector('lightning-input[data-id="term"]');
        termInput.value = 12;
        termInput.dispatchEvent(new CustomEvent('change'));

        // Trigger calculation
        const btn = element.shadowRoot.querySelector('lightning-button');
        btn.click();

        return Promise.resolve().then(() => {
            const resultDisplay = element.shadowRoot.querySelector('.result');
            expect(resultDisplay.textContent).toBe('Monthly Payment: $833.33');
        });
    });
});
