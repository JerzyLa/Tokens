import ether from './helpers/ether';
import { advanceBlock } from './helpers/advanceToBlock';
import { increaseTimeTo, duration } from './helpers/increaseTime';
import latestTime from './helpers/latestTime';
import EVMRevert from './helpers/EVMRevert';

const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const TimedStagesCrowdsale = artifacts.require('TimedStagesCrowdsale');
const MediarToken = artifacts.require('MediarToken');

contract('TimedStagesCrowdsale', function ([_, investor, wallet]) {
  const rate1 = new BigNumber(40000000);
  const rate2 = new BigNumber(20000000);
  const rate3 = new BigNumber(10000000);
  const minInvest = new BigNumber('1e17');
  const value = ether(1);
  const tokenSupply = new BigNumber('2e26');
  const expectedTokenAmount1 = rate1.mul(value);
  const expectedTokenAmount2 = rate2.mul(value);
  const expectedTokenAmount3 = rate3.mul(value);

  before(async function () {
    // Advance to the next block to correctly read time in the solidity "now" function interpreted by ganache
    await advanceBlock();
  });

  beforeEach(async function () {
    this.openingTime1 = latestTime() + duration.weeks(1);
    this.closingTime1 = this.openingTime1 + duration.weeks(1);
    this.openingTime2 = this.closingTime1 + duration.weeks(1);
    this.closingTime2 = this.openingTime2 + duration.weeks(1);
    this.openingTime3 = this.closingTime2 + duration.weeks(1);
    this.closingTime3 = this.openingTime3 + duration.weeks(1);
    this.openingTime4 = this.closingTime3 + duration.weeks(1);
    this.closingTime4 = this.openingTime4 + duration.weeks(1);
    this.afterClosingTime = this.closingTime4 + duration.seconds(1);
    
    this.token = await MediarToken.new();
    this.crowdsale = await TimedStagesCrowdsale.new(wallet, this.token.address, minInvest,
      rate1, this.openingTime1, this.closingTime1,
      rate2, this.openingTime2, this.closingTime2,
      rate3, this.openingTime3, this.closingTime3,
      this.openingTime4, this.closingTime4);
    await this.token.transfer(this.crowdsale.address, tokenSupply);
  });

  describe('general crowdsale test', function () {
    it('should have all token supply', async function () {
      const balance = await this.token.balanceOf(this.crowdsale.address);
      balance.should.be.bignumber.equal(tokenSupply);
    });
  
    it('should be ended after last stage', async function () {
      let ended = await this.crowdsale.hasClosed();
      ended.should.equal(false);
      await increaseTimeTo(this.afterClosingTime);
      ended = await this.crowdsale.hasClosed();
      ended.should.equal(true);
    });
  
    it('should be ended when no tokens left', async function () {
      await increaseTimeTo(this.openingTime1);
      let ended = await this.crowdsale.hasClosed();
      ended.should.equal(false);
      await this.crowdsale.buyTokens({ value: value*5, from: investor });
      const balance = await this.token.balanceOf(this.crowdsale.address);
      balance.should.be.bignumber.equal(0);
      ended = await this.crowdsale.hasClosed();
      ended.should.equal(true);
    });

    it('should reject other tokens', async function () {
      let newToken = await MediarToken.new();
      await newToken.transfer(this.crowdsale.address, tokenSupply).should.be.rejectedWith(EVMRevert);
    });
  });

  describe('accepting payments', function () {
    it('should reject payments before start', async function () {
      await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ from: investor, value: value }).should.be.rejectedWith(EVMRevert);
    });

    it('should accept payments after start first phase', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.send(value).should.be.fulfilled;
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.fulfilled;
    });

    it('should reject too low payments', async function () {
      await increaseTimeTo(this.openingTime1);
      const tooLowInvest = minInvest - 10;
      await this.crowdsale.send(tooLowInvest).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: tooLowInvest, from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should accept payments after start second phase', async function () {
      await increaseTimeTo(this.openingTime2);
      await this.crowdsale.send(value).should.be.fulfilled;
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.fulfilled;
    });

    it('should accept payments after start third phase', async function () {
      await increaseTimeTo(this.openingTime3);
      await this.crowdsale.send(value).should.be.fulfilled;
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.fulfilled;
    });

    it('should accept payments after start fourth phase', async function () {
      await increaseTimeTo(this.openingTime4);
      await this.crowdsale.send(value).should.be.fulfilled;
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.fulfilled;
    });

    it('should reject payments after end of first phase', async function () {
      await increaseTimeTo(this.afterClosingTime1);
      await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should reject payments after end of second phase', async function () {
      await increaseTimeTo(this.afterClosingTime2);
      await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should reject payments after end of third phase', async function () {
      await increaseTimeTo(this.afterClosingTime3);
      await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should reject payments after end of fourth phase', async function () {
      await increaseTimeTo(this.afterClosingTime4);
      await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.rejectedWith(EVMRevert);
    });
  });

  describe('token purchases', function () {
    it('should log purchase', async function () {
      await increaseTimeTo(this.openingTime1);
      const { logs } = await this.crowdsale.buyTokens({ value: value, from: investor });
      const event = logs.find(e => e.event === 'TokenPurchase');
      event.args.investor.should.equal(investor);
      event.args.value.should.be.bignumber.equal(value);
      event.args.amountOfTokens.should.be.bignumber.equal(expectedTokenAmount1);
    });

    it('should log postponed purchase when phase 4', async function () {
      await increaseTimeTo(this.openingTime4);
      const { logs } = await this.crowdsale.buyTokens({ value: value, from: investor });
      const event = logs.find(e => e.event === 'PostponedTokenPurchase');
      event.args.investor.should.equal(investor);
      event.args.value.should.be.bignumber.equal(value);
    });

    it('should assign tokens to beneficiary in phase1', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.buyTokens({ value, from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(expectedTokenAmount1);
    });

    it('should assign tokens to beneficiary in phase2', async function () {
      await increaseTimeTo(this.openingTime2);
      await this.crowdsale.buyTokens({ value, from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(expectedTokenAmount2);
    });

    it('should assign tokens to beneficiary in phase3 ', async function () {
      await increaseTimeTo(this.openingTime3);
      await this.crowdsale.buyTokens({ value, from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(expectedTokenAmount3);
    });

    it('should not assign tokens to beneficiary in phase 4 (token delivery postponed)', async function () {
      await increaseTimeTo(this.openingTime4);
      await this.crowdsale.buyTokens({ value, from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(0);
    });

    it('should forward funds to wallet in phase 1 after purchase', async function () {
      await increaseTimeTo(this.openingTime1);
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens({ value, from: investor });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });

    it('should forward funds to wallet in phase 2 after purchase', async function () {
      await increaseTimeTo(this.openingTime2);
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens({ value, from: investor });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });

    it('should forward funds to wallet in phase 3 after purchase', async function () {
      await increaseTimeTo(this.openingTime3);
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens({ value, from: investor });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });

    it('should forward funds to wallet in phase 4 (token delivery postponed)', async function () {
      await increaseTimeTo(this.openingTime4);
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens({ value, from: investor });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });
  });
});
