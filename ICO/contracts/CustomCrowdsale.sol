pragma solidity ^0.4.21;

import "./RefundableCrowdsale.sol";
import "./PostDeliveryCrowdsale.sol";

// ----------------------------------------------------------------------------
// @title CustomCrowdsale
// @dev Crowdsale contract is used for selling ERC223 tokens for setup price.
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
//      5. Refunding when goal not reached, withdrawl when crowdsale is finished.
//      6. AML token support
// ----------------------------------------------------------------------------
contract CustomCrowdsale is PostDeliveryCrowdsale, RefundableCrowdsale {
    using SafeMath for uint256;

    function CustomCrowdsale (
        address _wallet,
        ReleasableToken _token
    ) 
        public
        TimedStagesCrowdsale(_wallet, _token)
    {
        stages.push(Stage(4000, 500 finney, 1526050200, 1526053200, StageType.Standard));
        stages.push(Stage(3000, 200 finney, 1526056200, 1526059200, StageType.Standard));
        stages.push(Stage(2500, 200 finney, 1526062200, 1526065200, StageType.Standard));
        stages.push(Stage(2000, 200 finney, 1526068200, 1526071200, StageType.Standard));
        stages.push(Stage(0, 200 finney, 1526113800, 1526116800, StageType.PostDelivery));
    }
}
