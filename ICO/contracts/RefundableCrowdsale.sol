pragma solidity ^0.4.21; 

import "zeppelin-solidity/contracts/math/SafeMath.sol"; 
import "./utils/RefundVaultExt.sol"; 
import "./FinalizableCrowdsale.sol"; 

/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract add
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // refund vault used to hold funds while crowdsale is running
    RefundVaultExt public vault;

    /**
     * @dev Constructor, creates RefundVault.
     */
    function RefundableCrowdsale() public {
        vault = new RefundVaultExt(wallet);
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful
     */
    function claimRefund() public {
        require(isFinalized);

        vault.refund(msg.sender);
    }

    /**
     * @dev As an owner refund for investor, used when KYC 
     * check didn't pass.
     */
    function claimRefundForInvestor(address investor) public onlyOwner {
        require(investor != address(0));

        vault.refundAsOwner(investor);
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
}
