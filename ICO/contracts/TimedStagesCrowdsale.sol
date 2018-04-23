pragma solidity ^0.4.21;

import "./Tokens/ReleasableToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

// ----------------------------------------------------------------------------
// @title TimedStagesCrowdsale
// ----------------------------------------------------------------------------
contract TimedStagesCrowdsale is ContractReceiver {
    using SafeMath for uint256;

    enum StageType { Standard, Final }

    struct Stage {
        // How meny token units a buyer gets per ether
        uint256 rate;
        uint256 openingTime;
        uint256 closingTime;
        StageType stageType;
    }

    // The token being sold
    ReleasableToken public token; 
    
    // Address where funds are collected
    address public wallet;

    // Amount of wei collected
    uint256 public collectedAmountInWei;

    // Minimum amount of wei which can be invested
    uint256 public minInvest;

    // Crowdsale stages
    Stage[4] stages;

   /**
    * Event for token purchase logging
    * @param investor who bought tokens
    * @param value weis paid for purchase
    * @param amountOfTokens amount of tokens purchased
   */
    event TokenPurchase(address indexed investor, uint256 value, uint256 amountOfTokens);
    event PostponedTokenPurchase(address indexed investor, uint256 value);

    modifier onlyWhileOpen() {
        require(checkStage() >= 0);
        _;
    }

    function TimedStagesCrowdsale (
        address _wallet,
        ReleasableToken _token, 
        uint256 _minInvest,
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
        minInvest = _minInvest;
        stages[0] = Stage(_rate1, _openingTime1, _closingTime1, StageType.Standard);
        stages[1] = Stage(_rate2, _openingTime2, _closingTime2, StageType.Standard);
        stages[2] = Stage(_rate3, _openingTime3, _closingTime3, StageType.Standard);
        stages[3] = Stage(0, _finalOpeningTime, _finalClosingTime, StageType.Final);
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    function tokenFallback(address /*_from*/, uint /*_value*/, bytes /*_data*/) public {
        // accept only one type of ERC223 tokens
        require(ReleasableToken(msg.sender) == token);
    }

    function () external payable {
        buyTokens();
    }

    function buyTokens() public payable onlyWhileOpen {
        uint256 amountInWei = msg.value;
        require(amountInWei >= minInvest);
        
        uint8 stageNumber = uint8(checkStage());
        collectedAmountInWei = collectedAmountInWei.add(amountInWei);

        if (stages[stageNumber].stageType == StageType.Final) {
            _postponedTokenPurchase(msg.sender, amountInWei);
            emit PostponedTokenPurchase(msg.sender, amountInWei);
        } else {
            uint256 tokens = amountInWei.mul(stages[stageNumber].rate); 
            _tokenPurchase(msg.sender, tokens);
            emit TokenPurchase(msg.sender, amountInWei, tokens);
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

    function _tokenPurchase(address investor, uint tokens) internal {
        token.transfer(investor, tokens);
    }

    function _postponedTokenPurchase(address /*investor*/, uint /*amount*/) internal {
    }
}
