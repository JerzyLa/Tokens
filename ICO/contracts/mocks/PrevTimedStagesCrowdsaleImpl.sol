pragma solidity ^0.4.24;

import "../previous-contracts/PrevTimedStagesCrowdsale.sol";

contract PrevTimedStagesCrowdsaleImpl is PrevTimedStagesCrowdsale {
  constructor(
    address _wallet,
    ERC223  _token,
    uint256 _rate,
    uint256 _minInvest,
    uint256 _openingTime, 
    uint256 _closingTime 
  )
    public
    PrevTimedStagesCrowdsale(_wallet, _token)
  {
    stages.push(Stage(_rate, _minInvest, _openingTime, _closingTime));
  }
}
