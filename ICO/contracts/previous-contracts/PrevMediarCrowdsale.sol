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
    stages.push(Stage(4000, 500 finney, 1527811200, 1529020800));
    stages.push(Stage(3000, 200 finney, 1529107200, 1531699200));
    stages.push(Stage(2500, 200 finney, 1533254400, 1534723200));
    stages.push(Stage(2000, 200 finney, 1535673600, 1537142400));
    stages.push(Stage(0, 200 finney, 1539561600, 1540166400));
  }
}