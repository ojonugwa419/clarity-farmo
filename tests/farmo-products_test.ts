import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new product with history tracking",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const owner = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "farmo-products",
        "register-product",
        [
          types.uint(1),
          types.ascii("Apple"),
          types.ascii("Fresh red apples"),
          types.ascii("Farm A")
        ],
        owner.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(ok true)");
    
    // Check product history
    let historyResult = chain.callReadOnlyFn(
      "farmo-products",
      "get-product-history",
      [types.uint(1), types.uint(0), types.uint(10)],
      owner.address
    );
    
    assertEquals(historyResult.result.includes("registered"), true);
  }
});

Clarinet.test({
  name: "Ensure can update product status with history tracking",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const owner = accounts.get("wallet_1")!;
    
    // First register the product
    let block = chain.mineBlock([
      Tx.contractCall(
        "farmo-products",
        "register-product",
        [
          types.uint(1),
          types.ascii("Apple"),
          types.ascii("Fresh red apples"),
          types.ascii("Farm A")
        ],
        owner.address
      )
    ]);
    
    // Then update status
    block = chain.mineBlock([
      Tx.contractCall(
        "farmo-products",
        "update-status",
        [
          types.uint(1),
          types.ascii("in-transit")
        ],
        owner.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(ok true)");
    
    // Check status update in history
    let historyResult = chain.callReadOnlyFn(
      "farmo-products",
      "get-product-history",
      [types.uint(1), types.uint(0), types.uint(10)],
      owner.address
    );
    
    assertEquals(historyResult.result.includes("status-update"), true);
  }
});
