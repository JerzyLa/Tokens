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

contract('TimedStagesCrowdsale', function ([_, investor, wallet, purchaser]) {
  const rate1 = new BigNumber(1);
  const rate2 = new BigNumber(2);
  const rate3 = new BigNumber(4);
  const value = ether(42);
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
    this.afterClosingTime = this.closingTime4 + duration.seconds(1);
    
    this.token = await MediarToken.new();
    this.crowdsale = await TimedStagesCrowdsale.new(wallet, this.token.address, 
      rate1, this.openingTime1, this.closingTime1,
      rate2, this.openingTime2, this.closingTime2,
      rate3, this.openingTime3, this.closingTime3,
      this.openingTime4, this.closingTime4);
    await this.token.transfer(this.crowdsale.address, tokenSupply);
  });

  it('should be ended after last stage', async function () {
    let ended = await this.crowdsale.hasClosed();
    ended.should.equal(false);
    await increaseTimeTo(this.afterClosingTime);
    ended = await this.crowdsale.hasClosed();
    ended.should.equal(true);
  });

  // describe('accepting payments', function () {
  //   it('should reject payments before start', async function () {
  //     await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
  //     await this.crowdsale.buyTokens(investor, { from: purchaser, value: value }).should.be.rejectedWith(EVMRevert);
  //   });

  //   it('should accept payments after start', async function () {
  //     await increaseTimeTo(this.openingTime);
  //     await this.crowdsale.send(value).should.be.fulfilled;
  //     await this.crowdsale.buyTokens(investor, { value: value, from: purchaser }).should.be.fulfilled;
  //   });

  //   it('should reject payments after end', async function () {
  //     await increaseTimeTo(this.afterClosingTime);
  //     await this.crowdsale.send(value).should.be.rejectedWith(EVMRevert);
  //     await this.crowdsale.buyTokens(investor, { value: value, from: purchaser }).should.be.rejectedWith(EVMRevert);
  //   });
  // });
});
