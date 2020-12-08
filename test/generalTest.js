const TokenFA12 = artifacts.require("TokenFA12");
const assert = require("assert");
const accounts = require("../scripts/sandbox/accounts");
const { InMemorySigner } = require("@taquito/signer");

contract("TokenFA12", async function () {
  it("should check initial storage", async function () {
    const instance = await TokenFA12.deployed();
    const storage = await instance.storage();
    const aliceAddress = accounts.alice.pkh;
    const totalSupply = storage.totalSupply;
    const aliceRecord = await storage.ledger.get(aliceAddress);
    assert.strictEqual(totalSupply.toNumber(), 1000);
    assert.strictEqual(aliceRecord.balance.toNumber(), 1000);
  });
  it("should transfer tokens from Alice to Bob", async function () {
    const instance = await TokenFA12.deployed();
    const aliceAddress = accounts.alice.pkh;
    const bobAddress = accounts.bob.pkh;
    const value = 100;
    await instance.transfer(aliceAddress, bobAddress, value);
    const storage = await instance.storage();
    const aliceRecord = await storage.ledger.get(aliceAddress);
    const bobRecord = await storage.ledger.get(bobAddress);
    assert.strictEqual(aliceRecord.balance.toNumber(), 900);
    assert.strictEqual(bobRecord.balance.toNumber(), 100);
  });
  it.only("should fail if transfer isn't approved", async function () {
    const instance = await TokenFA12.deployed();
    const aliceAddress = accounts.alice.pkh;
    tezos.setSignerProvider(
      await InMemorySigner.fromSecretKey(accounts.bob.sk)
    );
    const bobAddress = accounts.bob.pkh;
    const value = 10000;
    await assert.rejects(
      instance.transfer(aliceAddress, bobAddress, value),
      (err) => {
        assert.strictEqual(err.message, "NotPermitted", "Wrong error message");
        return true;
      },
      "No error is emitted"
    );
  });
});
