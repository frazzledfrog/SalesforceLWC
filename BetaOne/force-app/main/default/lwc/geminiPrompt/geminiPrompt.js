import { LightningElement } from 'lwc';
import { withUnifiedStyles } from 'c/unifiedStylesHelper';
import getGeminiResponse from '@salesforce/apex/GeminiApiService.getGeminiResponse';

const INITIAL_PROMPT = 'Enter your prompt here...';

/**
 * Simple UI to send prompts to a Gemini API and display responses.
 */
export default class GeminiPrompt extends withUnifiedStyles(LightningElement) {
    prompt = INITIAL_PROMPT;
    apiResponse = '';
    apiError = '';
    isLoading = false;

    /**
     * Track changes to the prompt textarea.
     */
    handlePromptChange(event) {
        this.prompt = event.target.value;
    }

    /**
     * Call the Gemini API and process the response.
     */
    handleCallApi() {
        if (this.prompt && this.prompt !== INITIAL_PROMPT) {
            this.apiResponse = '';
            this.apiError = '';
            this.isLoading = true;

            getGeminiResponse({ prompt: this.prompt })
                .then(result => {
                    const parsedResult = JSON.parse(result);
                    const responseText = parsedResult.candidates?.[0]?.content?.parts?.[0]?.text;

                    if (responseText) {
                        this.apiResponse = responseText;
                    } else {
                        this.apiError = 'Could not parse the text from the API response.';
                    }
                })
                .catch(error => {
                    this.apiError = error.body ? error.body.message : 'An unknown error occurred.';
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.apiError = 'Please enter a prompt before sending a request.';
        }
    }

    /**
     * Reset the prompt and response fields.
     */
    handleClear() {
        this.prompt = INITIAL_PROMPT;
        this.apiResponse = '';
        this.apiError = '';
        this.isLoading = false;
    }
}