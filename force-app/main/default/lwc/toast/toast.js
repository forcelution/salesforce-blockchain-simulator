import { ShowToastEvent } from 'lightning/platformShowToastEvent'

/**
 * Show a Lightning Toast
 * @param {string} variant - The toast type. Valid values are: info, success, warning, and error.
 * @param {string} message - A string representing the body of the message.
 */
const showToast = (variant, message) => {
    const event = new ShowToastEvent({
        variant: variant,
        message: message
    });
    dispatchEvent(event);
}

export {
    showToast
}