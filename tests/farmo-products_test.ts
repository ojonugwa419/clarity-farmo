import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new product",
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
  }
});

Clarinet.test({
  name: "Ensure can transfer product ownership",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const owner = accounts.get("wallet_1")!;
    const newOwner = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "farmo-products",
        "transfer-product",
        [
          types.uint(1),
          types.principal(newOwner.address)
        ],
        owner.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(ok true)");
  }
});
