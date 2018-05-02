pragma solidity ^0.4.21; 

import "zeppelin-solidity/contracts/math/SafeMath.sol"; 
import "./TimedStagesCrowdsale.sol"; 

/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract PostDeliveryCrowdsale is TimedStagesCrowdsale, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public weiBalances;
    uint256 public weiRaised;
    uint256 public tokensLeft;
    bool once = true;

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

        // get tokens left after closing crowdsale
        getTokensLeftOnlyOnce();

        uint256 amount = (weiBalances[investor].mul(tokensLeft)).div(weiRaised);
        require(amount > 0);
        weiBalances[investor] = 0;
        _tokenPurchase(investor, amount);
    }

    function getTokensLeftOnlyOnce() internal {
        if(once) {
            tokensLeft = token.balanceOf(this);
            once = false;
        } 
    }

    /**
     * @dev Overrides parent by storing balances instead of issuing tokens right away.
     * @param _beneficiary Token purchaser
     * @param _amountInWei payed for tokens
     */
    function _postponedTokenPurchase(address _beneficiary, uint256 _amountInWei) internal {
        weiBalances[_beneficiary] = weiBalances[_beneficiary].add(_amountInWei);
        weiRaised = weiRaised.add(_amountInWei);
    }

}