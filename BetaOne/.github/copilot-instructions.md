# Salesforce Apex & LWC Project Instructions

This document provides guidance for AI coding agents working on this Salesforce project.

## Architecture Overview

This is a Salesforce DX (SFDX) project. The backend is built with **Apex** and the frontend with **Lightning Web Components (LWC)**.

-   **Apex Controllers**: Backend logic is located in `force-app/main/default/classes/`. These classes contain business logic and data access methods.
-   **LWC Components**: Frontend components are in `force-app/main/default/lwc/`. They call Apex methods to interact with Salesforce data.
-   **Data Model**: The application uses standard Salesforce objects like `Account` and `User`, along with custom objects like `talkdesk__Talkdesk_Activity__c`.

## Key Patterns & Conventions

### Apex Controllers

-   **`@AuraEnabled` Methods**: Public methods intended to be called from the frontend (LWC) must be annotated with `@AuraEnabled`. For read-only methods that don't change data, use `@AuraEnabled(cacheable=true)` for better performance.

    *Example from `TalkdeskActivityController.cls`*:
    ```apex
    @AuraEnabled(cacheable=true)
    public static List<SalespersonInfo> getSalespeople() {
        // ...
    }
    ```

-   **Wrapper Classes**: Use inner classes to define structured data objects to return to the frontend. This keeps the API contract clean.

    *Example from `TalkdeskActivityController.cls`*:
    ```apex
    public class TalkdeskActivityData {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String salespersonId { get; set; }
        // ...
    }
    ```

-   **Dynamic SOQL & Apex Aggregation**: For queries with multiple optional filters, the code often builds SOQL queries dynamically. Instead of complex aggregate SOQL, the pattern is to query for raw records and then perform aggregation and calculations in Apex using `Map` objects.

    *Example from `TalkdeskActivityController.getTalkdeskActivityData`*:
    ```apex
    // 1. Build a dynamic SOQL string
    String query = 'SELECT ... FROM talkdesk__Talkdesk_Activity__c WHERE ...';
    // ... add filters ...
    List<talkdesk__Talkdesk_Activity__c> rawActivities = Database.query(query);

    // 2. Group and aggregate in Apex
    Map<String, TalkdeskActivityData> groupedData = new Map<String, TalkdeskActivityData>();
    for (talkdesk__Talkdesk_Activity__c activity : rawActivities) {
        // ... logic to group and sum data ...
    }
    ```

-   **Error Handling**: All `@AuraEnabled` methods should wrap their logic in a `try-catch` block and throw an `AuraHandledException` to propagate errors to the LWC frontend.

    *Example from `TalkdeskActivityController.cls`*:
    ```apex
    try {
        // ... logic ...
    } catch (Exception e) {
        throw new AuraHandledException('Error retrieving data: ' + e.getMessage());
    }
    ```

### Testing

-   **Test Classes**: Apex test classes must be named with a `Test` suffix (e.g., `MyControllerTest.cls`).
-   **Test Data**: Create test data within test methods or in a dedicated `@testSetup` method. Do not rely on existing data in the org.

## Interaction Model

-   **Clarify Intent**: Before implementing any feature, it is crucial to ask clarifying questions to ensure a complete understanding of the requirements. If a request is ambiguous or lacks detail, break it down into smaller pieces and confirm the proposed approach before writing any code. This proactive communication helps prevent rework and ensures the final output aligns perfectly with the user's goals. Always seek clarification on acceptance criteria, edge cases, and desired behavior.

