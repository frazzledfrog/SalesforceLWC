// Gemini Prompt component handles UI logic and data interactions
import { LightningElement } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';
import getGeminiResponse from '@salesforce/apex/GeminiApiService.getGeminiResponse';

const INITIAL_PROMPT = 'Enter your prompt here...';

export default class GeminiPrompt extends LightningElement {
    prompt = INITIAL_PROMPT;
    apiResponse = '';
    apiError = '';
    isLoading = false;

    handlePromptChange(event) {
        this.prompt = event.target.value;
    }

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

    handleClear() {
        this.prompt = INITIAL_PROMPT;
        this.apiResponse = '';
        this.apiError = '';
        this.isLoading = false;
    }

    async connectedCallback() {
        await loadUnifiedStyles(this);
    }
}