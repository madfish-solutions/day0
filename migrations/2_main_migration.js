const TokenFA12 = artifacts.require("TokenFA12");
const { MichelsonMap } = require("@taquito/taquito");

module.exports = async (deployer, _network, accounts) => {
  const totalSupply = "1000";
  const storage = {
    totalSupply,
    ledger: MichelsonMap.fromLiteral({
      [accounts[0]]: {
        balance: totalSupply,
        allowances: MichelsonMap.fromLiteral({}),
      },
    }),
  };
  deployer.deploy(TokenFA12, storage);
};
