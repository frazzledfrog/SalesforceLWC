// Global ambient type declarations for LWC + Salesforce modules

// Example custom module declaration (extend as needed)
declare module 'c/unifiedStylesHelper' {
  export function loadUnifiedStyles(ctx: any): Promise<void>;
}

// Example Salesforce module shim additions if not already provided by generated typings
// (Adjust or remove if duplicates cause conflicts.)
declare module '@salesforce/apex/TopDealersController.getTopDealersWithLimit' {
  export default function getTopDealersWithLimit(params: { region: string; limitCount: number | null }): Promise<Array<{ accountName: string; totalAmount: number; regionTotal: number }>>;
}
