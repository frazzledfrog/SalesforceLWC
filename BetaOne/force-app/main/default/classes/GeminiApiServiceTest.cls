@isTest
private class GeminiApiServiceTest {

    @TestSetup
    static void makeData(){
        // Create and insert a sample testing__c record.
        testing__c testRecord = new testing__c(
            main_name_first__c = 'Test',
            main_name_last__c = 'Record',
            merchant__c = 'Test Merchant',
            program__c = 'Test Program',
            loan_ID__c = 'L-123456',
            amount_financed__c = 5000.00,
            date_funded__c = Date.today()
        );
        insert testRecord;
    }

    @isTest
    static void testGetGeminiResponseSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        String testPrompt = 'What is this record?';
        String jsonResponse;

        Test.startTest();
        jsonResponse = GeminiApiService.getGeminiResponse(testPrompt);
        Test.stopTest();

        Assert.isNotNull(jsonResponse, 'Response should not be null on success.');

        Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> candidates = (List<Object>) parsedResponse.get('candidates');
        Assert.isTrue(candidates != null && !candidates.isEmpty(), 'Candidates list should not be empty.');
        
        Map<String, Object> firstCandidate = (Map<String, Object>) candidates[0];
        Map<String, Object> content = (Map<String, Object>) firstCandidate.get('content');
        List<Object> parts = (List<Object>) content.get('parts');
        Map<String, Object> firstPart = (Map<String, Object>) parts[0];
        String responseText = (String) firstPart.get('text');

        Assert.areEqual('This is a mock success response', responseText, 'Response text should match the mock success body.');
    }

    @isTest
    static void testGetGeminiResponseError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500));
        String testPrompt = 'This will fail';
        Boolean exceptionWasThrown = false;

        Test.startTest();
        
        try {
            GeminiApiService.getGeminiResponse(testPrompt);
        } catch (AuraHandledException e) {
            exceptionWasThrown = true;
        }
        
        Test.stopTest();

        Assert.isTrue(exceptionWasThrown, 'An AuraHandledException was expected but not thrown.');
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;

        public MockHttpResponseGenerator(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (this.statusCode == 200) {
                String mockBody = '{' +
                '  "candidates": [' +
                '    {' +
                '      "content": {' +
                '        "parts": [' +
                '          {' +
                '            "text": "This is a mock success response"' +
                '          }' +
                '        ]' +
                '      }' +
                '    }' +
                '  ]' +
                '}';
                res.setBody(mockBody);
                res.setStatusCode(200);
                res.setStatus('OK');
            } else {
                res.setBody('{"error": "Internal server error"}');
                res.setStatusCode(500);
                res.setStatus('Server Error');
            }
            return res;
        }
    }
}