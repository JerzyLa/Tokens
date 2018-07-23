pragma solidity ^0.4.24;

import "./PrevRefundableCrowdsale.sol";
import "./PrevPostDeliveryCrowdsale.sol";

contract PrevMediarCrowdsale is PrevPostDeliveryCrowdsale, PrevRefundableCrowdsale {
  using SafeMath for uint256;

  constructor(
    address _wallet,
    ReleasableToken _token
  ) 
    public
    PrevTimedStagesCrowdsale(_wallet, _token)
  {
    stages.push(Stage(2500, 200 finney, 1532217600, 1532304000));
    stages.push(Stage(2000, 200 finney, 1532304001, 1532390340));
  }
}