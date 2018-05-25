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

const TimedStagesCrowdsaleImpl = artifacts.require('TimedStagesCrowdsaleImpl');
const MediarToken = artifacts.require('MediarToken');

contract('TimedStagesCrowdsaleImpl', function ([_, owner, investor, wallet]) {
  const rate1 = new BigNumber(100000000);
  const value = ether(1);
  const minInvest1 = new BigNumber('5e17');
  const minInvest2 = new BigNumber('2e17');
  const tokenSupply = new BigNumber('4e26');
  const expectedTokenAmount1 = rate1.mul(value);

  before(async function () {
    // Advance to the next block to correctly read time in the solidity "now" function interpreted by ganache
    await advanceBlock();
  });

  beforeEach(async function () {
    this.openingTime1 = latestTime() + duration.weeks(1);
    this.closingTime1 = this.openingTime1 + duration.weeks(1);
    this.openingTimeLast = this.closingTime1 + duration.weeks(1);
    this.closingTimeLast = this.openingTimeLast + duration.weeks(1);
    this.afterClosingTime = this.closingTimeLast + duration.seconds(1);
    
    this.token = await MediarToken.new({ from: owner });
    this.crowdsale = await TimedStagesCrowdsaleImpl.new(wallet, this.token.address, 
      rate1, minInvest1, this.openingTime1, this.closingTime1,
      minInvest2, this.openingTimeLast, this.closingTimeLast
    );

    await this.token.setTransferAgent(owner, true, { from: owner });
    await this.token.setTransferAgent(this.crowdsale.address, true, { from: owner });
    await this.token.transfer(this.crowdsale.address, tokenSupply, { from: owner });
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
      await this.crowdsale.buyTokens({ value: value*4, from: investor });
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

    it('should accept payments after start first stage', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.send(value).should.be.fulfilled;
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.fulfilled;
    });

    it('should accept payments after start last stage', async function () {
      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.send(value).should.be.fulfilled;
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.fulfilled;
    });

    it('should reject payments after end of first stage', async function () {
      await increaseTimeTo(this.afterClosingTime1);
      await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should reject payments after end of last stage', async function () {
      await increaseTimeTo(this.afterClosingTimeLast);
      await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: value, from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should reject payments when invest less than minimum after start first stage', async function () {
      await increaseTimeTo(this.openingTime1);
      const tooLowInvest = minInvest1 - 100;
      await this.crowdsale.send(tooLowInvest).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: tooLowInvest, from: investor }).should.be.rejectedWith(EVMRevert);
    });

    it('should reject payments when invest less than minimum after start last stage', async function () {
      await increaseTimeTo(this.openingTimeLast);
      const tooLowInvest = minInvest2 - 100;
      await this.crowdsale.send(tooLowInvest).should.be.rejectedWith(EVMRevert);
      await this.crowdsale.buyTokens({ value: tooLowInvest, from: investor }).should.be.rejectedWith(EVMRevert);
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

    it('should assign tokens to beneficiary in stage1', async function () {
      await increaseTimeTo(this.openingTime1);
      await this.crowdsale.buyTokens({ value, from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(expectedTokenAmount1);
    });

    it('should not assign tokens to beneficiary in last stage (token delivery postponed)', async function () {
      await increaseTimeTo(this.openingTimeLast);
      await this.crowdsale.buyTokens({ value, from: investor });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(0);
    });

    it('should forward funds to wallet in stage 1 after purchase', async function () {
      await increaseTimeTo(this.openingTime1);
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens({ value, from: investor });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });

    it('should forward funds to wallet in Last stage (token delivery postponed)', async function () {
      await increaseTimeTo(this.openingTimeLast);
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens({ value, from: investor });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });
  });
});
