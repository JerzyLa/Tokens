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

  contract('MediarCrowdsale', function ([_, owner, wallet, thirdparty, investor, purchaser]) {
    const rate1 = new BigNumber(40000000);
    const rate2 = new BigNumber(20000000);
    const rate3 = new BigNumber(10000000);
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
      this.crowdsale = await MediarCrowdsale.new(wallet, this.token.address, 
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

    describe('Postponed tokens delivery', function() {
      it('should not immediately assign tokens to beneficiary in phase 4', async function () {
        await increaseTimeTo(this.openingTime4);
        await this.crowdsale.buyTokens(investor, { value: value, from: purchaser });
        const balance = await this.token.balanceOf(investor);
        balance.should.be.bignumber.equal(0);
      });

      it('should not allow beneficiaries to withdraw tokens before crowdsale ends', async function () {
        await increaseTimeTo(this.beforeEndTime);
        await this.crowdsale.buyTokens(investor, { value: value, from: purchaser });
        await this.crowdsale.withdrawTokens({ from: investor }).should.be.rejectedWith(EVMRevert);
      });

      it('should allow beneficiaries to withdraw tokens after crowdsale ends', async function () {
        await increaseTimeTo(this.openingTime4);
        await this.crowdsale.buyTokens(investor, { value: value, from: purchaser });
        await increaseTimeTo(this.afterClosingTime);
        await this.crowdsale.withdrawTokens({ from: investor }).should.be.fulfilled;
      });
    });
  });