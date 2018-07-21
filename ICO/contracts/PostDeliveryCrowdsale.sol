pragma solidity ^0.4.21; 

import "openzeppelin-solidity/contracts/math/SafeMath.sol"; 
import "./RefundableCrowdsale.sol"; 
import "./previous-contracts/PrevPostDeliveryCrowdsale.sol";

/**
  * @title PostDeliveryCrowdsale
  * @dev Crowdsale that locks tokens from withdrawal until it ends.
  */
contract PostDeliveryCrowdsale is RefundableCrowdsale {
  using SafeMath for uint256;

  // bonus tokens available after crowdsale are withdrawned or not.
  mapping(address => bool) public withdrawned;
  
  // left tokens, which will be distributed after crowdsale
  uint256 public tokensForDistribution = 0;

  constructor() public {
    for(uint i = 0; i < investors.length; ++i) {
      address investor = investors[i];
      investedAmountOf[investor] = PrevPostDeliveryCrowdsale(oldCrowdsale).shares(investor);
    }
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
    require(investor != address(0));
    _withdrawTokens(investor);
  }

  function _withdrawTokens(address investor) internal {
    require(tokensForDistribution != 0);
    require(withdrawned[investor] == false, "Investor withdrew the funds previously");
    
    withdrawned[investor] = true;
    uint256 amount = tokensForDistribution.mul(investedAmountOf[investor]).div(collectedAmountInWei-weiRefunded);
    require(amount != 0);
    _tokenPurchase(investor, amount);
  }

  /**
    * @dev vault finalization task, called when owner calls finalize()
    * when successful release token and disable refunding.
    */
  function finalization(bool isSuccessful) internal {
    if (isSuccessful) {
      tokensForDistribution = token.balanceOf(this);
    } 

    super.finalization(isSuccessful);
  }
  
}