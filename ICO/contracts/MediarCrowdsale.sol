pragma solidity ^0.4.21;

import "./OwnerRefundableCrowdsale.sol";

// ----------------------------------------------------------------------------
// @title MediarCrowdsale
// @dev Crowdsale contract is used for selling ERC20 tokens for setup price.
// Below points describes rules for distributing tokens by this contract.
//      1. Sale is only available during certain period of time called phase.
//         There will be only 4 phases during whole ICO distribution.
//      2. Price for single token will be constant during phase. Every next phase 
//         will start with higher price for token.
//      3. At the end of final phase all unsold tokens will be distributed among
//         token buers in that phase. Addresses which will have purchased more tokens 
//         will receive proportionally more unsold tokens. (Probably addresses with marginal 
//         amount of tokens will not take part in final token distribution) 
//      4. After final phase there will not be possible to buy more tokens. 
//         Payable functions will be disabled.
//      5. Refunding when goal not reached, withdrawl when goal is reached.
// ----------------------------------------------------------------------------
contract MediarCrowdsale is OwnerRefundableCrowdsale {
    using SafeMath for uint256;

    function MediarCrowdsale (
        address _wallet,
        ERC20 _token, // TODO: change token to ERC223
        uint256 _rate1, uint256 _openingTime1, uint256 _closingTime1,
        uint256 _rate2, uint256 _openingTime2, uint256 _closingTime2,
        uint256 _rate3, uint256 _openingTime3, uint256 _closingTime3
    ) 
        public
        TimedStagesCrowdsale(_wallet, _token, _rate1, _openingTime1, _closingTime1,
            _rate2, _openingTime2, _closingTime2, _rate3, _openingTime3, _closingTime3)
    {
    }
}
