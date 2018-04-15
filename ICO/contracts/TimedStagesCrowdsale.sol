pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

// ----------------------------------------------------------------------------
// @title TimedStagesCrowdsale
// ----------------------------------------------------------------------------
contract TimedStagesCrowdsale {
    using SafeMath for uint256;

    enum StageType { Standard, Final }

    struct Stage {
        // How meny token units a buyer gets per wei
        uint256 rate;
        uint256 openingTime;
        uint256 closingTime;
        StageType stageType;
    }

    // The token being sold
    ERC20 public token;  // TODO: change token to ERC223 or different
    
    // Address where funds are collected
    address public wallet;

    // Amount of wei collected
    uint256 public collectedAmountInWei;

    // Crowdsale stages
    Stage[4] stages;

   /**
    * Event for token purchase logging
    * @param buyer who bought tokens
    * @param value weis paid for purchase
    * @param amountOfTokens amount of tokens purchased
   */
    event TokenPurchased(address buyer, uint256 value, uint256 amountOfTokens);
    event PostponedTokenPurchased(address buyer, uint256 value);

    modifier onlyWhileOpen() {
        require(checkStage() >= 0);
        _;
    }

    function TimedStagesCrowdsale (
        address _wallet,
        ERC20 _token, 
        uint256 _rate1, uint256 _openingTime1, uint256 _closingTime1,
        uint256 _rate2, uint256 _openingTime2, uint256 _closingTime2,
        uint256 _rate3, uint256 _openingTime3, uint256 _closingTime3,
        uint256 _finalOpeningTime, uint256 _finalClosingTime
    ) 
        public
    {
        require(_wallet != address(0));
        require(_token != address(0));
        require(_rate1 > 0);
        require(_openingTime1 >= block.timestamp);
        require(_closingTime1 >= _openingTime1);
        require(_rate2 > 0);
        require(_openingTime2 >= _closingTime1);
        require(_closingTime2 >= _openingTime2);
        require(_rate3 > 0);
        require(_openingTime3 >= _closingTime2);
        require(_closingTime3 >= _openingTime3);
        require(_finalOpeningTime >= _closingTime3);
        require(_finalClosingTime >= _finalOpeningTime);

        wallet = _wallet;
        token = _token;
        stages[0] = Stage(_rate1, _openingTime1, _closingTime1, StageType.Standard);
        stages[1] = Stage(_rate2, _openingTime2, _closingTime2, StageType.Standard);
        stages[2] = Stage(_rate3, _openingTime3, _closingTime3, StageType.Standard);
        stages[3] = Stage(0, _finalOpeningTime, _finalClosingTime, StageType.Final);
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    function () external payable onlyWhileOpen {
        require(msg.value != 0);
        
        uint256 amountInWei = msg.value;
        uint8 stageNumber = uint8(checkStage());
        collectedAmountInWei = collectedAmountInWei.add(amountInWei);

        if (stages[stageNumber].stageType == StageType.Final) {
            _postponedTokenPurchase(msg.sender, amountInWei);
            emit PostponedTokenPurchased(msg.sender, amountInWei);
        } else {
            uint256 tokens = amountInWei.mul(stages[stageNumber].rate); 
            _tokenPurchase(msg.sender, tokens);
            emit TokenPurchased(msg.sender, amountInWei, tokens);
        }
        _forwardFunds();
    }

    function hasClosed() public view returns (bool) {
        return (
            block.timestamp > stages[stages.length-1].closingTime ||
            token.balanceOf(this) == 0
        );
    }

    // -----------------------------------------
    // Internal interface (extensible) - similar to protected
    // -----------------------------------------

    function checkStage() internal view returns(int8) {
        for (uint8 i = 0; i < stages.length; ++i) {
            if (block.timestamp <= stages[i].closingTime && block.timestamp >= stages[i].openingTime) {
                return int8(i);
            }
        }
        
        return -1;
    } 

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function _tokenPurchase(address beneficiary, uint tokens) internal {
        token.transfer(beneficiary, tokens);
    }

    function _postponedTokenPurchase(address /*beneficiary*/, uint /*amount*/) internal {
    }
}
