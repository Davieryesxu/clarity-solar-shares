import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can add new solar panel",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('solar-panel-shares', 'add-panel', [
                types.uint(1000000), // price per share
                types.uint(100)      // total shares
            ], deployer.address),
            // Non-owner attempt should fail
            Tx.contractCall('solar-panel-shares', 'add-panel', [
                types.uint(1000000),
                types.uint(100)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0); // First panel ID = 0
        block.receipts[1].result.expectErr().expectUint(100); // ERR_NOT_AUTHORIZED
    }
});

Clarinet.test({
    name: "Can buy shares and verify ownership",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('solar-panel-shares', 'add-panel', [
                types.uint(1000000),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('solar-panel-shares', 'buy-shares', [
                types.uint(0),  // panel ID
                types.uint(10)  // number of shares
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        
        // Verify shares
        let getShares = chain.mineBlock([
            Tx.contractCall('solar-panel-shares', 'get-shares', [
                types.uint(0),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        assertEquals(getShares.receipts[0].result, types.uint(10));
    }
});

Clarinet.test({
    name: "Can record energy generation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('solar-panel-shares', 'add-panel', [
                types.uint(1000000),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('solar-panel-shares', 'record-energy', [
                types.uint(0),    // panel ID
                types.uint(1000)  // watts generated
            ], deployer.address),
            // Non-owner attempt should fail
            Tx.contractCall('solar-panel-shares', 'record-energy', [
                types.uint(0),
                types.uint(1000)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectOk();
        block.receipts[2].result.expectErr().expectUint(100); // ERR_NOT_AUTHORIZED
    }
});
