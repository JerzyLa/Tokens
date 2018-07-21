pragma solidity ^0.4.21;

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
    stages.push(Stage(2500, 200 finney, 1532131200, 1532217600));
    stages.push(Stage(2000, 200 finney, 1532217601, 1532304000));
  }
}