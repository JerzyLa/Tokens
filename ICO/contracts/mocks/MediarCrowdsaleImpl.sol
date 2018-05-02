pragma solidity ^0.4.21;

import "../PostDeliveryCrowdsale.sol";
import "../RefundableCrowdsale.sol";


contract MediarCrowdsaleImpl is PostDeliveryCrowdsale, RefundableCrowdsale {
    function MediarCrowdsaleImpl (
        address _wallet,
        ReleasableToken _token,
        uint256 _rate1,
        uint256 _minInvest1,
        uint256 _openingTime1, 
        uint256 _closingTime1,
        uint256 _minInvest2,
        uint256 _openingTime2, 
        uint256 _closingTime2
    )
        public
        TimedStagesCrowdsale(_wallet, _token)
    {
        stages.push(Stage(_rate1, _minInvest1, _openingTime1, _closingTime1, StageType.Standard));
        stages.push(Stage(0, _minInvest2, _openingTime2, _closingTime2, StageType.PostDelivery));
    }
}