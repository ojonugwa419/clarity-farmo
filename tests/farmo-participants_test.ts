import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register participant",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const participant = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "farmo-participants",
        "register-participant",
        [
          types.ascii("Farmer John"),
          types.ascii("farmer")
        ],
        participant.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(ok true)");
  }
});

Clarinet.test({
  name: "Ensure only owner can verify participants",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const owner = accounts.get("deployer")!;
    const participant = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "farmo-participants",
        "verify-participant",
        [types.principal(participant.address)],
        owner.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, "(ok true)");
  }
});
