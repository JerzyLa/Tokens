pragma solidity ^0.4.21;

import "./RefundableCrowdsale.sol";
import "./PostDeliveryCrowdsale.sol";

// ----------------------------------------------------------------------------
// @title MediarCrowdsale
// @dev Crowdsale contract is used for selling ERC223 tokens for setup price.
// Below points describes rules for distributing tokens by this contract.
//      1. Sale is only available during certain period of time called stage.
//         There will be only 5 stages during ICO.
//      2. Price for single token will be constant during standard stage. Every next stage 
//         will start with higher price for token.
//      3. At the end of final stage all unsold tokens will be distributed among
//         token buers in that stage. Addresses which purchased more tokens 
//         would receive proportionally more unsold tokens. 
//      4. After final stage, wont be possible to buy more tokens. 
//         Payable functions will be disabled.
//      5. Refunding when goal not reached 
//      6. AML token support
// ----------------------------------------------------------------------------
contract MediarCrowdsale is PostDeliveryCrowdsale, RefundableCrowdsale {
    using SafeMath for uint256;

    function MediarCrowdsale (
        address _wallet,
        ReleasableToken _token
    ) 
        public
        TimedStagesCrowdsale(_wallet, _token)
    {
        stages.push(Stage(4000, 500 finney, 1526342400, 1529020800, StageType.Standard));
        stages.push(Stage(3000, 200 finney, 1529107200, 1531699200, StageType.Standard));
        stages.push(Stage(2500, 200 finney, 1533254400, 1534723200, StageType.Standard));
        stages.push(Stage(2000, 200 finney, 1535673600, 1537142400, StageType.Standard));
        stages.push(Stage(0, 200 finney, 1539561600, 1540166400, StageType.PostDelivery));
    }
}