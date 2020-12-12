const TokenFA12 = artifacts.require("TokenFA12");
const { MichelsonMap } = require("@taquito/taquito");

module.exports = async (deployer, _network, accounts) => {
  const totalSupply = "1000";
  const totalStaked = "0";
  const rewardPerShare = "0";
  const lastUpdateTime = "0";
  const storage = {
    totalStaked,
    rewardPerShare,
    lastUpdateTime,
    totalSupply,
    ledger: MichelsonMap.fromLiteral({
      [accounts[0]]: {
        balance: totalSupply,
        staked: totalStaked,
        lastRewardPerShare: lastUpdateTime,
        allowances: MichelsonMap.fromLiteral({}),
      },
    }),
  };
  deployer.deploy(TokenFA12, storage);
};
