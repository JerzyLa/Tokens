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
    mapping(address => uint256) public tokenBalances;
    uint256 weiRaised;

    /**
     * @dev Constructor, creates RefundVault.
     */
    function OwnerRefundableCrowdsale() public {
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
     * @dev Withdraw tokens only after crowdsale ends.
     */
    function withdrawTokens() public {
        require(isFinalized);
        uint256 amount = tokenBalances[msg.sender];
        require(amount > 0);
        tokenBalances[msg.sender] = 0;
        _tokenPurchase(msg.sender, amount);
    }

    /**
     * @dev vault finalization task, called when owner calls finalize()
     */
    function finalization(bool success) internal {
        giveTokens();
        if (success) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        super.finalization(success);
    }

    function giveTokens() private {
        // TODO: how to calc it ?
        // for (uint8 i = 0; i < weiBalances.size(); ++i) {
        //     uint256 tokens = weiBalances[i].div(weiRaised);
        //     tokenBalances[i] = tokens;
        // }
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
