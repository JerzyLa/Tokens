pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol"; 


contract RefundVaultExt is RefundVault
{
    function RefundVaultExt(address _wallet) public RefundVault(_wallet) {

    }

    /**
     * As an owner I can always refund.
     */
    function refundAsOwner(address investor) public onlyOwner {
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}