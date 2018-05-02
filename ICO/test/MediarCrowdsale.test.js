import ether from './helpers/ether';
import { advanceBlock } from './helpers/advanceToBlock';
import { increaseTimeTo, duration } from './helpers/increaseTime';
import latestTime from './helpers/latestTime';
import EVMRevert from './helpers/EVMRevert';

const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const MediarCrowdsaleImpl = artifacts.require('MediarCrowdsaleImpl');
const MediarToken = artifacts.require('MediarToken');

contract('MediarCrowdsaleImpl', function ([_, owner, wallet, thirdparty, investor, investor1, investor2, investor3]) {
  const rate1 = new BigNumber(100000000);
  const value = ether(1);
  const minInvest1 = new BigNumber('5e17');
  const minInvest2 = new BigNumber('2e17');
  const tokenSupply = new BigNumber('2e26');

  before(async function () {
    // Advance to the next block to correctly read time in the solidity "now" function interpreted by ganache
    await advanceBlock();
  });

  beforeEach(async function () {
    this.openingTime1 = latestTime() + duration.weeks(1);
    this.closingTime1 = this.openingTime1 + duration.weeks(1);
    this.openingTimeLast = this.closingTime1 + duration.weeks(1);
    this.closingTimeLast = this.openingTimeLast + duration.weeks(1);
    this.beforeEndTime = this.closingTimeLast - duration.hours(1);
    this.afterClosingTime = this.closingTimeLast + duration.seconds(1);
    
    this.token = await MediarToken.new({ from: owner });
    this.crowdsale = await MediarCrowdsaleImpl.new(wallet, this.token.address,
      rate1, minInvest1, this.openingTime1, this.closingTime1,
      minInvest2, this.openingTimeLast, this.closingTimeLast,
      { from: owner }
    );

    await this.token.setTransferAgent(owner, true, { from: owner });
    await this.token.setTransferAgent(this.crowdsale.address, true, { from: owner });
    await this.token.setReleaseAgent(this.crowdsale.address, { from: owner });
    await this.token.transfer(this.crowdsale.address, tokenSupply, { from: owner });
  });

  describe('Crowdsale finalization', function () {
    it('cannot be finalized before ending', async function () {
      await this.crowdsale.finalize(true, { from: owner }).should.be.rejectedWith(EVMRevert);
    });
  
    it('cannot be finalized by third party after ending', async function () {
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.finalize(true, { from: thirdparty }).should.be.rejectedWith(EVMRevert);
    });
  
    it('can be finalized by owner after ending', async function () {
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.finalize(true, { from: owner }).should.be.fulfilled;
    });
  
    it('cannot be finalized twice', async function () {
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.finalize(true, { from: owner });
      await this.crowdsale.finalize(true, { from: owner }).should.be.rejectedWith(EVMRevert);
    });
  
    it('logs finalized', async function () {
      await increaseTimeTo(this.afterClosingTime);
      const { logs } = await this.crowdsale.finalize(false, { from: owner });
      const event = logs.find(e => e.event === 'Finalized');
      should.exist(event);
    });
  });

  describe('Postponed tokens delivery last stage', function() {
    it('should not immediately assign tokens to beneficiary in last stage', async function () {
      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.buyTokens({ value: value, from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(0);
    });

    it('should not allow beneficiaries to withdraw tokens before crowdsale ends', async function () {
      await increaseTimeTo(this.beforeEndTime);
      await this.crowdsale.buyTokens({ value: value, from: investor });
      await this.crowdsale.withdrawTokens({ from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should allow beneficiaries to withdraw tokens after crowdsale ends', async function () {
      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.buyTokens({ value: value, from: investor });
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.withdrawTokens({ from: investor }).should.be.fulfilled;
    });

    it('should allow to withdraw tokens after last stage', async function () {
      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.buyTokens({ value: value, from: investor });
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.withdrawTokens({ from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(tokenSupply);
    });

    it('should allow owner to withdraw tokens for investor after last stage', async function () {
      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.buyTokens({ value: value, from: investor });
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.withdrawTokensForInvestor(investor, { from: owner });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(tokenSupply);
    });

    it('should spread the amount of tokens left to all purchases in last stage', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.buyTokens({ value: value, from: investor });

      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.buyTokens({ value: value, from: investor1 });
      await this.crowdsale.buyTokens({ value: value.mul(2), from: investor2 });
      await this.crowdsale.buyTokens({ value: value.mul(3), from: investor3 });
      await increaseTimeTo(this.afterClosingTime);
      
      await this.crowdsale.withdrawTokens({ from: investor1 });
      let balance = await this.token.balanceOf(investor1);
      balance.should.be.bignumber.equal('1.6666666666666666666666666e25');
      
      await this.crowdsale.withdrawTokens({ from: investor2 });
      balance = await this.token.balanceOf(investor2);
      balance.should.be.bignumber.equal('3.3333333333333333333333333e25');

      await this.crowdsale.withdrawTokens({ from: investor3 });
      balance = await this.token.balanceOf(investor3);
      balance.should.be.bignumber.equal('5e25');
    });
  });

  describe('Rafundable', function() {
    it('should deny refunds before end', async function () {
      await this.crowdsale.claimRefund({ from: investor }).should.be.rejectedWith(EVMRevert);
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.claimRefund({ from: investor }).should.be.rejectedWith(EVMRevert);
    });
  
    it('should deny refunds after end if finalized succesfully', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.sendTransaction({ value: value, from: investor });
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.finalize(true, { from: owner });
      await this.crowdsale.claimRefund({ from: investor }).should.be.rejectedWith(EVMRevert);
    });
  
    it('should allow refunds after end if finalized unsuccesfully', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.sendTransaction({ value: value, from: investor });
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.finalize(false, { from: owner });
      const pre = web3.eth.getBalance(investor);
      await this.crowdsale.claimRefund({ from: investor, gasPrice: 0 })
        .should.be.fulfilled;
      const post = web3.eth.getBalance(investor);
      post.minus(pre).should.be.bignumber.equal(value);
    });

    it('should allow owner to refund for investor after end if finalized unsuccesfully', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.sendTransaction({ value: value, from: investor });
      await increaseTimeTo(this.afterClosingTime);
      await this.crowdsale.finalize(false, { from: owner });
      const pre = web3.eth.getBalance(investor);
      await this.crowdsale.claimRefundForInvestor(investor, { from: owner, gasPrice: 0 })
        .should.be.fulfilled;
      const post = web3.eth.getBalance(investor);
      post.minus(pre).should.be.bignumber.equal(value);
    });
  
    it('should forward funds to wallet after end  finalized succesfully', async function () {
      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.sendTransaction({ value: value, from: investor });
      await increaseTimeTo(this.afterClosingTime);
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.finalize(true, { from: owner });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });
  });
});