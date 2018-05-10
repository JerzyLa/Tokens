pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ERC223/ERC223_Interface.sol";
import "./ERC223/Receiver_Interface.sol";

// ----------------------------------------------------------------------------
// @title TimedStagesCrowdsale
// ----------------------------------------------------------------------------
contract TimedStagesCrowdsale is ContractReceiver {
    using SafeMath for uint256;

    enum StageType { Standard, PostDelivery }

    struct Stage {
        // How meny token units a buyer gets per ether
        uint256 rate;
        uint256 minInvest;
        uint256 openingTime;
        uint256 closingTime;
        StageType stageType;
    }

    // The token being sold
    ERC223 public token; 
    
    // Address where funds are collected
    address public wallet;

    // Amount of wei collected
    uint256 public collectedAmountInWei;

    // Crowdsale stages
    Stage[] public stages;

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

    function TimedStagesCrowdsale (address _wallet, ERC223 _token) public {
        require(_wallet != address(0));
        require(_token != address(0));

        wallet = _wallet;
        token = _token;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /*
     * @dev For ERC223 callback
     */
    function tokenFallback(address /*_from*/, uint /*_value*/, bytes /*_data*/) public {
        // accept only one type of ERC223 tokens
        require(ERC223(msg.sender) == token);
    }

    function () external payable {
        buyTokens();
    }

    function buyTokens() public payable onlyWhileOpen {
        uint256 amountInWei = msg.value;
        uint8 stageNumber = uint8(checkStage());
        require(amountInWei >= stages[stageNumber].minInvest);
        require(amountInWei != 0);

        // update state
        collectedAmountInWei = collectedAmountInWei.add(amountInWei);

        if (stages[stageNumber].stageType == StageType.PostDelivery) {
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
        // optional override
    }
}
