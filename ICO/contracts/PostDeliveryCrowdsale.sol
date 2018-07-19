pragma solidity ^0.4.21; 

import "openzeppelin-solidity/contracts/math/SafeMath.sol"; 
import "./TimedStagesCrowdsale.sol"; 

/**
  * @title PostDeliveryCrowdsale
  * @dev Crowdsale that locks tokens from withdrawal until it ends.
  */
contract PostDeliveryCrowdsale is TimedStagesCrowdsale, Ownable {
  using SafeMath for uint256;

  // bonus tokens available after crowdsale are withdrawned or not.
  mapping(address => bool) public withdrawned;
  
  // left tokens, which will be distributed after crowdsale
  uint256 public tokensForDistribution;
  
  bool once = true;

  constructor() public {
    // TODO: move to main contract
    // for(uint i=0; i<investors.length; ++i) {
    //   address investor = investors[i];
    //   shares[investor].add(PostDeliveryCrowdsale(oldCrowdsale).shares(investor));
    // }
  }

  /**
    * @dev Withdraw tokens only after crowdsale ends.
    */
  function withdrawTokens() public {
    _withdrawTokens(msg.sender);
  }

  /**
    * @dev As an owner withdraw tokens for investor only after crowdsale ends.
    */
  function withdrawTokensForInvestor(address investor) public onlyOwner {
    _withdrawTokens(investor);
  }

  function _withdrawTokens(address investor) internal {
    require(hasClosed());
    require(investor != address(0));
    require(withdrawned[investor] == false, "Investor withdrew the funds previously");

    withdrawned[investor] = true;

    // get tokens left after closing crowdsale
    getTokensForDistribution();

    uint256 amount = tokensForDistribution.mul(investedAmountOf[investor]).div(collectedAmountInWei);
    require(amount != 0);
    _tokenPurchase(investor, amount);
  }

  function getTokensForDistribution() internal {
    if(once) {
      once = false;
      tokensForDistribution = token.balanceOf(this);
    }
  }
  
}