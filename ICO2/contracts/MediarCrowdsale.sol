pragma solidity ^0.4.24;

import "./TimedCrowdsale.sol";
import "./tokens/ReleasableToken.sol";

contract MediarCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  constructor(
    uint256 openingTime,
    uint256 closingTime,
    uint256 rate,
    uint256 minInvest,
    address wallet,
    ReleasableToken token
  )
    public
    Crowdsale(rate, minInvest, wallet, token)
    TimedCrowdsale(openingTime, closingTime)
  {
  }
}
