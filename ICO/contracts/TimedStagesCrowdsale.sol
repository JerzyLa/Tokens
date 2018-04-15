pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

// ----------------------------------------------------------------------------
// @title TimedStagesCrowdsale
// ----------------------------------------------------------------------------
contract TimedStagesCrowdsale {
    using SafeMath for uint256;

    struct Stage {
        // How meny token units a buyer gets per wei
        uint256 rate;
        uint256 openingTime;
        uint256 closingTime;
    }

    // The token being sold
    ERC20 public token;  // TODO: change token to ERC223 or different
    
    // Address where funds are collected
    address public wallet;

    // Amount of wei collected
    uint256 public collectedAmountInWei;

    // Crowdsale stages
    Stage[3] stages;

   /**
    * Event for token purchase logging
    * @param buyer who bought tokens
    * @param value weis paid for purchase
    * @param amountOfTokens amount of tokens purchased
   */
    event TokenPurchased(address buyer, uint256 value, uint256 amountOfTokens);

    modifier onlyWhileOpen() {
        require(checkPhase() >= 0);
        _;
    }

    function TimedStagesCrowdsale (
        address _wallet,
        ERC20 _token, 
        uint256 _rate1, uint256 _openingTime1, uint256 _closingTime1,
        uint256 _rate2, uint256 _openingTime2, uint256 _closingTime2,
        uint256 _rate3, uint256 _openingTime3, uint256 _closingTime3
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

        wallet = _wallet;
        token = _token;
        stages[0] = Stage(_rate1, _openingTime1, _closingTime1);
        stages[1] = Stage(_rate2, _openingTime2, _closingTime2);
        stages[2] = Stage(_rate3, _openingTime3, _closingTime3);
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    // TODO: change phase 2
    function () external payable onlyWhileOpen {
        require(msg.value != 0);
        
        uint256 amountInWei = msg.value;
        uint256 tokens = amountInWei.mul(stages[uint8(checkPhase())].rate); 
        collectedAmountInWei = collectedAmountInWei.add(amountInWei);

        token.transfer(msg.sender, tokens);
        emit TokenPurchased(msg.sender, amountInWei, tokens);
        _forwardFunds();
    }

    // TODO: Contract can be also closed manually
    function hasClosed() public view returns (bool) {
        return (
            block.timestamp > stages[stages.length-1].closingTime ||
            token.balanceOf(this) == 0
        );
    }

    // -----------------------------------------
    // Internal interface (extensible) - similar to protected
    // -----------------------------------------

    function checkPhase() internal view returns(int8) {
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
}
