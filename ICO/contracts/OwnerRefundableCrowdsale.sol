pragma solidity ^0.4.21; 

import "zeppelin-solidity/contracts/math/SafeMath.sol"; 
import "zeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol"; 
import "./FinalizableWithResultCrowdsale.sol"; 

/**
 * @title OwnerRefundableCrowdsale
 * @dev Extension of Crowdsale contract add
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
contract OwnerRefundableCrowdsale is FinalizableWithResultCrowdsale {
    using SafeMath for uint256;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

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
     * @dev vault finalization task, called when owner calls finalize()
     */
    function finalization(bool success) internal {
        if (success) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        super.finalization(success);
    }

    /**
    * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
    */
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }
}
