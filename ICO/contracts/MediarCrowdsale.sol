pragma solidity ^0.4.24;

import "./RefundableCrowdsale.sol";
import "./PostDeliveryCrowdsale.sol";

// ----------------------------------------------------------------------------
// @title MediarCrowdsale
// @dev Crowdsale contract is used for selling ERC223 tokens.
// Below points describes rules for tokens distribution by this contract.
//      1. Sale is only available during certain period of time called stage.
//      2. Price for single token will be constant during standard stage. Every next stage 
//         will start with higher price for token.
//      3. At the end of final stage all unsold tokens will be distributed among
//         token buers investors. Addresses which purchased more tokens 
//         would receive proportionally more unsold tokens.
//      4. After final stage, won't be possible to buy more tokens. 
//         Payable functions will be disabled.
//      5. Refunding when goal not reached.
//      6. AML token support.
// ----------------------------------------------------------------------------
contract MediarCrowdsale is PostDeliveryCrowdsale {
  using SafeMath for uint256;

  constructor(
    address oldCrowdsale
  ) 
    public
    TimedStagesCrowdsale(oldCrowdsale)
  {
    // stages.push(Stage(3000, 200 finney, 1533254400, 1536364799));
    // stages.push(Stage(2500, 200 finney, 1536883200, 1538783999));
    // stages.push(Stage(2000, 200 finney, 1539302400, 1541203199));
    // stages.push(Stage(0, 200 finney, 1541807999, 1543622399));

    stages.push(Stage(2000, 200 finney, 1532217601, 1532359680));
  }
}
