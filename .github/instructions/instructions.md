---
mode: agent
---
# LWC Copilot Agent Instructions

**Purpose**: This repository builds Salesforce Lightning Web Components (LWC) with optional Apex services. These instructions tell an AI coding agent ("Copilot") exactly how to propose, generate, and modify code here.

---

## 1) Repo assumptions & layout

* **Source root**: `force-app/main/default`
* **Key folders**

  * `lwc/` → all LWCs (`lwc/<name>/*`)
  * `classes/` → Apex services (`*.cls` + `*.cls-meta.xml`)
  * `objects/` → Metadata definitions (fields, validation, etc.)
  * `messageChannels/` → Lightning Message Service channels
  * `labels/` → Custom labels for i18n / text constants
  * `staticresources/` → Only when absolutely necessary (Locker-safe)
* **Tests**

  * LWC Jest: `force-app/test/jest/*`
  * Apex: `force-app/main/default/classes/*_Test.cls`
* **CLI**: We use the new `sf` CLI.

---

## 2) Copilot behavior (how to respond)

When asked to add/modify features, **always**:

1. **Summarize** the change in 1–2 sentences.
2. **Show a file tree** of new/changed files.
3. Provide **complete file contents** for each changed file (no ellipses), with correct paths.
4. Explain **why** key choices were made (data access, security, perf) in ≤5 bullets.
5. Include **how to run**: `sf` commands and `npm` scripts relevant to the change.
6. Use **Conventional Commits** for example commit messages.

If requirements are ambiguous, pick sane defaults (noted as assumptions) and proceed. Minimize chatter; ship code.

---

## 3) Language, frameworks, and style

* **LWC first**: Prefer base Lightning components (`lightning-*`) and LDS (Lightning Data Service) over custom Apex where possible.
* **JavaScript** (no TypeScript in this repo unless requested). Use modern syntax, modules, and getters.
* **Styling**: SLDS utility classes preferred; avoid heavy custom CSS. Never inline styles that break Locker.
* **Naming**: kebab-case folder names for LWCs (e.g., `account-list`), camelCase JS symbols, UpperCamelCase Apex classes.
* **i18n**: Use Custom Labels for user-facing strings.

---

## 4) Data access rules

* **Use LDS first**: `lightning-record-form`, `lightning-record-edit-form`, or UI API wire adapters (`@salesforce/ui*Api`).
* **Apex only when needed** (complex queries, cross-object aggregations, DML not supported by LDS).
* **Wire first, imperative if necessary**: Use `@wire` with `cacheable=true` for read ops; imperative Apex for filtered queries triggered by user actions.
* **Limit fields** to what is rendered; never query `SELECT *` style.
* **Refresh**: Use `refreshApex` after DML or LMS messages when data should update.

---

## 5) Security & compliance (must-have)

Copilot must always:

* Enforce **CRUD/FLS** in Apex using `Schema.sObjectType` checks before reading/writing fields.
* Respect **with sharing** unless explicitly justified. No broad `without sharing`.
* Avoid leaking data via debug logs or UI.
* Keep to **Locker Service** and CSP rules; no direct DOM traversal outside LWC APIs; no `eval`/unsafe globals.
* Use **Custom Labels** for text; **Custom Permissions** / **Permission Sets** for feature gates where needed.

---

## 6) UX, a11y, and events

* Prefer base `lightning-*` components and SLDS utilities.
* Provide **keyboard navigation** and ARIA attributes for custom elements.
* Show feedback via **toasts** (`ShowToastEvent`) and busy states (e.g., `aria-busy`, spinners).
* For inter-component comms across the DOM, use **Lightning Message Service**.
* Lists: set a stable `key` on iterables; virtualize only if needed.

---

## 7) Performance guidelines

* Cache with `@wire(cacheable=true)`; debounce user inputs for queries.
* Avoid large, synchronous loops in the browser; paginate server responses.
* Don’t chain multiple imperative Apex calls when one purpose-built method suffices.
* Avoid re-render churn: compute with getters; prefer immutable updates.

---

## 8) Testing requirements

* **LWC (Jest)**: Write unit tests for render, wire success/error, and user interaction.
* **Apex**: Separate `_Test` classes; ≥75% coverage for changed classes; test both positive and negative paths, including CRUD/FLS behavior.
* No network in unit tests; mock wires and Apex.

**Commands**

```bash
npm run test        # LWC unit tests (configure in package.json)
sf apex run test -r human --test-level RunLocalTests
```

---

## 9) Tooling & scripts

**Common CLI**

```bash
sf plugins install salesforcedx
sf org create scratch -f config/project-scratch-def.json -a dev -s
sf project deploy start -o dev
sf lightning generate component --name myComponent --type lwc --output-dir force-app/main/default/lwc
sf apex class create --classname MyService --outputdir force-app/main/default/classes
```

**Recommended NPM scripts (example)**

```json
{
  "scripts": {
    "lint": "eslint force-app/main/default/lwc --ext .js",
    "test": "lwc-jest --coverage",
    "prettier": "prettier --write 'force-app/**/*.{{js,html,css,json}}'"
  }
}
```

---

## 10) Commit / PR standards

* **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:`
* PR must include: purpose, screenshots/GIF for UI, risk notes (CRUD/FLS, sharing), and test proof.

---

## 11) Code templates

### 11.1 LWC skeleton

```
# File: force-app/main/default/lwc/exampleList/exampleList.js
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getExamples from '@salesforce/apex/ExampleService.getExamples';

export default class ExampleList extends LightningElement {
  records = [];
  error;
  loading = true;

  @wire(getExamples)
  wiredExamples({ data, error }) {
    this.loading = false;
    if (data) {
      this.records = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Load failed',
          message: Array.isArray(error?.body?.pageErrors) ? error.body.pageErrors.map(e => e.message).join('; ') : 'Unexpected error',
          variant: 'error'
        })
      );
    }
  }
}
```

```
# File: force-app/main/default/lwc/exampleList/exampleList.html
<template>
  <lightning-card title="Examples" icon-name="custom:custom63">
    <template if:true={loading}>
      <lightning-spinner alternative-text="Loading"></lightning-spinner>
    </template>

    <template if:true={records}>
      <lightning-layout multiple-rows>
        <template for:each={records} for:item="rec">
          <lightning-layout-item key={rec.Id} size="12">
            <p class="slds-p-vertical_x-small">{rec.Name}</p>
          </lightning-layout-item>
        </template>
      </lightning-layout>
    </template>

    <template if:true={error}>
      <c-error-panel errors={error}></c-error-panel>
    </template>
  </lightning-card>
</template>
```

```
# File: force-app/main/default/lwc/exampleList/exampleList.css
:host { display: block; }
```

```
# File: force-app/main/default/lwc/exampleList/exampleList.js-meta.xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
  <apiVersion>61.0</apiVersion>
  <isExposed>true</isExposed>
  <targets>
    <target>lightning__RecordPage</target>
    <target>lightning__AppPage</target>
    <target>lightning__HomePage</target>
  </targets>
</LightningComponentBundle>
```

### 11.2 Apex service (CRUD/FLS-safe)

```
# File: force-app/main/default/classes/ExampleService.cls
public with sharing class ExampleService {
  @AuraEnabled(cacheable=true)
  public static List<Account> getExamples() {
    // FLS/CRUD check: read Name field on Account
    if (!Schema.sObjectType.Account.fields.Name.isAccessible()) {
      throw new AuraHandledException('Insufficient access to Account.Name');
    }
    return [SELECT Id, Name FROM Account ORDER BY Name LIMIT 100];
  }
}
```

```
# File: force-app/main/default/classes/ExampleService.cls-meta.xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
  <apiVersion>61.0</apiVersion>
  <status>Active</status>
</ApexClass>
```

### 11.3 LWC Jest test

```
# File: force-app/test/jest/exampleList/exampleList.test.js
import { createElement } from 'lwc';
import ExampleList from 'c/exampleList';
import getExamples from '@salesforce/apex/ExampleService.getExamples';

jest.mock(
  '@salesforce/apex/ExampleService.getExamples',
  () => ({ default: jest.fn() }),
  { virtual: true }
);

describe('c-example-list', () => {
  afterEach(() => {
    while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
    jest.clearAllMocks();
  });

  it('renders records', async () => {
    getExamples.mockResolvedValue([{ Id: '001', Name: 'Acme' }]);
    const el = createElement('c-example-list', { is: ExampleList });
    document.body.appendChild(el);
    await Promise.resolve();
    expect(el.shadowRoot.textContent).toContain('Acme');
  });

  it('handles error', async () => {
    getExamples.mockRejectedValue({ body: { message: 'boom' } });
    const el = createElement('c-example-list', { is: ExampleList });
    document.body.appendChild(el);
    await Promise.resolve();
    // Basic smoke check; real test would assert toast/error panel
    expect(getExamples).toHaveBeenCalled();
  });
});
```

### 11.4 Lightning Message Service channel

```
# File: force-app/main/default/messageChannels/ExampleChannel.messageChannel-meta.xml
<?xml version="1.0" encoding="UTF-8"?>
<MessageChannel xmlns="http://soap.sforce.com/2006/04/metadata">
  <masterLabel>ExampleChannel</masterLabel>
  <isExposed>true</isExposed>
  <description>Cross-component notifications</description>
</MessageChannel>
```

---

## 12) Common patterns & snippets

* **Toast helper**

  ```js
  import { ShowToastEvent } from 'lightning/platformShowToastEvent';
  const toast = (cmp, title, message, variant='info') =>
    cmp.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  export default toast;
  ```
* **Record edit form**

  ```html
  <lightning-record-edit-form object-api-name="Account" record-id={recordId} onsuccess={handleSaved}>
    <lightning-messages></lightning-messages>
    <lightning-input-field field-name="Name"></lightning-input-field>
    <lightning-button type="submit" label="Save"></lightning-button>
  </lightning-record-edit-form>
  ```
* **Imperative Apex with spinner**

  ```js
  this.loading = true;
  someMethod({ param: this.value })
    .then(r => { /* set state */ })
    .catch(e => { /* toast error */ })
    .finally(() => { this.loading = false; });
  ```
* **refreshApex**

  ```js
  import { refreshApex } from '@salesforce/apex';
  // keep last wired result in a property, then call refreshApex(wiredHandle)
  ```

---

## 13) Example response format (what Copilot should output)

> **feat: add example list LWC**
>
> **Tree**
>
> * `force-app/main/default/classes/ExampleService.cls`
> * `force-app/main/default/classes/ExampleService.cls-meta.xml`
> * `force-app/main/default/lwc/exampleList/*`
> * `force-app/test/jest/exampleList/exampleList.test.js`
>
> **Run**
>
> ```bash
> sf project deploy start
> npm run test
> ```
>
> **Notes**
>
> * Uses LDS-compatible read via cacheable Apex
> * Enforces FLS on Account.Name
> * Toasts on error; minimal CSS; SLDS utilities
> * Jest covers success & error paths

---

## 14) Guardrails (what NOT to do)

* No direct DOM manipulation outside LWC APIs (no `querySelector` across shadow roots unless within own template).
* No global window/document operations or third-party libs without `staticresources` + `platformResourceLoader` and Locker review.
* No SOQL in loops; bulkify all Apex; handle limits.
* No hard-coded Ids or org-specific URLs; use labels and metadata.

---

## 15) Ready-made checklists

**LWC PR checklist**

* [ ] Base components + SLDS used where possible
* [ ] Toasts and loading states present
* [ ] Wire adapters cacheable; imperative calls debounced
* [ ] Unit tests added/updated (Jest)
* [ ] i18n via labels; no hard-coded copy

**Apex PR checklist**

* [ ] `with sharing` and FLS/CRUD checks
* [ ] Bulkified; test for >200 records
* [ ] Selective fields only; no `SELECT Id, Name, ...` without reason
* [ ] `_Test` class with ≥75% coverage and negative tests

---

## 16) Quick-start commands

```bash
# Create a new LWC
sf lightning generate component --name accountList --type lwc --output-dir force-app/main/default/lwc

# Create an Apex service
sf apex class create --classname AccountListService --outputdir force-app/main/default/classes

# Deploy & test
sf project deploy start
npm run test
sf apex run test -r human --tests AccountListService_Test
```

---

**End of instructions**
