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

  const MediarCrowdsale = artifacts.require('MediarCrowdsale');
  const MediarToken = artifacts.require('MediarToken');

  contract('MediarCrowdsale', function ([_, owner, wallet, thirdparty, investor, investor1, investor2, investor3]) {
    const rate1 = new BigNumber(40000000);
    const rate2 = new BigNumber(20000000);
    const rate3 = new BigNumber(10000000);
    const minInvest = new BigNumber('5e17');
    const value = ether(1);
    const tokenSupply = new BigNumber('2e26');

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
      this.beforeEndTime = this.closingTime4 - duration.hours(1);
      this.afterClosingTime = this.closingTime4 + duration.seconds(1);
      
      this.token = await MediarToken.new();
      this.crowdsale = await MediarCrowdsale.new(wallet, this.token.address, minInvest,
        rate1, this.openingTime1, this.closingTime1,
        rate2, this.openingTime2, this.closingTime2,
        rate3, this.openingTime3, this.closingTime3,
        this.openingTime4, this.closingTime4, { from: owner }
      );
      await this.token.transfer(this.crowdsale.address, tokenSupply);
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

    describe('Postponed tokens delivery (phase 4)', function() {
      it('should not immediately assign tokens to beneficiary in phase 4', async function () {
        await increaseTimeTo(this.openingTime4);
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
        await increaseTimeTo(this.openingTime4);
        await this.crowdsale.buyTokens({ value: value, from: investor });
        await increaseTimeTo(this.afterClosingTime);
        await this.crowdsale.withdrawTokens({ from: investor }).should.be.fulfilled;
      });

      it('should allow to withdraw tokens after phase 4', async function () {
        await increaseTimeTo(this.openingTime4);
        await this.crowdsale.buyTokens({ value: value, from: investor });
        await increaseTimeTo(this.afterClosingTime);
        await this.crowdsale.withdrawTokens({ from: investor });
        const balance = await this.token.balanceOf(investor);
        balance.should.be.bignumber.equal(tokenSupply);
      });

      it('should allow owner to withdraw tokens for investor after phase 4', async function () {
        await increaseTimeTo(this.openingTime4);
        await this.crowdsale.buyTokens({ value: value, from: investor });
        await increaseTimeTo(this.afterClosingTime);
        await this.crowdsale.withdrawTokensForInvestor(investor, { from: owner });
        const balance = await this.token.balanceOf(investor);
        balance.should.be.bignumber.equal(tokenSupply);
      });

      it('should spread the amount of tokens left to all purchases in this 4 phase', async function () {
        await increaseTimeTo(this.openingTime1);
        await this.crowdsale.buyTokens({ value: value, from: investor });

        await increaseTimeTo(this.openingTime4);
        await this.crowdsale.buyTokens({ value: value, from: investor1 });
        await this.crowdsale.buyTokens({ value: value.mul(2), from: investor2 });
        await this.crowdsale.buyTokens({ value: value.mul(3), from: investor3 });
        await increaseTimeTo(this.afterClosingTime);
        
        await this.crowdsale.withdrawTokens({ from: investor1 });
        let balance = await this.token.balanceOf(investor1);
        balance.should.be.bignumber.equal('2.6666666666666666666666666e25');
        
        await this.crowdsale.withdrawTokens({ from: investor2 });
        balance = await this.token.balanceOf(investor2);
        balance.should.be.bignumber.equal('5.3333333333333333333333333e25');

        await this.crowdsale.withdrawTokens({ from: investor3 });
        balance = await this.token.balanceOf(investor3);
        balance.should.be.bignumber.equal('8e25');
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
        await increaseTimeTo(this.openingTime4);
        await this.crowdsale.sendTransaction({ value: value, from: investor });
        await increaseTimeTo(this.afterClosingTime);
        const pre = web3.eth.getBalance(wallet);
        await this.crowdsale.finalize(true, { from: owner });
        const post = web3.eth.getBalance(wallet);
        post.minus(pre).should.be.bignumber.equal(value);
      });
    });
  });