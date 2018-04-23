pragma solidity ^0.4.21; 

import "zeppelin-solidity/contracts/math/SafeMath.sol"; 
import "zeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol"; 
import "./FinalizableCrowdsale.sol"; 

/**
 * @title PostDeliveryAndRefundableCrowdsale
 * @dev Extension of Crowdsale contract add
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
contract PostDeliveryAndRefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    mapping(address => uint256) public weiBalances;
    uint256 public weiRaised;
    uint256 public tokensLeft;
    bool once = true;

    /**
     * @dev Constructor, creates RefundVault.
     */
    function PostDeliveryAndRefundableCrowdsale() public {
        vault = new RefundVault(wallet);
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful
     */
    function claimRefund() public {
        require(isFinalized);

        vault.refund(msg.sender);
    }

    /**
     * @dev As an owner refund for investor if crowdsale is unsuccessful
     */
    function claimRefundForInvestor(address investor) public onlyOwner {
        require(isFinalized);
        require(investor != address(0));

        vault.refund(investor);
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
     * @dev vault finalization task, called when owner calls finalize()
     */
    function finalization(bool success) internal {
        if (success) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        token.releaseTokenTransfer();
        super.finalization(success);
    }

    /**
    * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
    */
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
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
