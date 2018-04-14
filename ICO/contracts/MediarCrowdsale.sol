pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

// ----------------------------------------------------------------------------
// @title MediarCrowdsale
// @dev Crowdsale contract is used for selling ERC20 tokens for setup price.
// Below points describes rules for distributing tokens by this contract.
//      1. Sale is only available during certain period of time called phase.
//         There will be only 4 phases during whole ICO distribution.
//      2. Price for single token will be constant during phase. Every next phase 
//         will start with higher price for token.
//      3. At the end of final phase all unsold tokens will be distributed among
//         token buers in that phase. Addresses which will have purchased more tokens 
//         will receive proportionally more unsold tokens. (Probably addresses with marginal 
//         amount of tokens will not take part in final token distribution) 
//      4. 
//         After final phase there will not be possible to buy more tokens. 
//         Payable functions will be disabled.
//      5. What is set goal ? Withdrawl when goal not reached, withdrawl when goal is reached ?
// ----------------------------------------------------------------------------
contract MediarCrowdsale is Ownable {
    using SafeMath for uint256;

    struct Phase {
        // How meny token units a buyer gets per wei
        uint256 rate;
        uint256 openingTime;
        uint256 closingTime;
    }

    /// TODO: states can be moved to parent or child contract
    enum State { Active, Refunding, Closed }

    // The token being sold
    ERC20 public token;  // TODO: change token to ERC223 or different
    
    // Address where funds are collected
    address public wallet;

    // Amount of wei collected
    uint256 public collectedAmountInWei;

    // Crowdsale states 
    State state;
    Phase[3] phases;

   /**
    * Event for token purchase logging
    * @param buyer who bought tokens
    * @param value weis paid for purchase
    * @param amountOfTokens amount of tokens purchased
   */
    event TokenPurchased(address buyer, uint256 value, uint256 amountOfTokens);

    modifier crowdsaleClosed() {
        require(state == State.Closed);
        _;
    }

    modifier onlyWhileOpen() {
        require(state == State.Active);
        require(checkPhase() >= 0);
        _;
    }

    function MediarCrowdsale (
        address _wallet,
        ERC20 _token, 
        uint256 _rate1, uint256 _openingTime1, uint256 _closingTime1,
        uint256 _rate2, uint256 _openingTime2, uint256 _closingTime2,
        uint256 _rate3, uint256 _openingTime3, uint256 _closingTime3
        ) public
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
        state = State.Active;
        phases[0] = Phase(_rate1, _openingTime1, _closingTime1);
        phases[1] = Phase(_rate2, _openingTime2, _closingTime2);
        phases[2] = Phase(_rate3, _openingTime3, _closingTime3);
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    // TODO: add crowdsale closed status
    // TODO: change phase 2
    function () external payable onlyWhileOpen {
        require(msg.value != 0);
        
        uint256 amountInWei = msg.value;
        uint256 tokens = amountInWei.mul(phases[uint8(checkPhase())].rate); 
        collectedAmountInWei = collectedAmountInWei.add(amountInWei);

        token.transfer(msg.sender, tokens);
        emit TokenPurchased(msg.sender, amountInWei, tokens);
        forwardFunds(); // Czy to ma być, czy tylko na końcu transfer ?
    }

    // TODO: Contract can be also closed manually
    function hasClosed() public view returns (bool) {
        return block.timestamp > phases[phases.length-1].closingTime;
    }

    function withdrawal() public view onlyOwner crowdsaleClosed {

    }

    function refunding() public view onlyOwner crowdsaleClosed {

    }

    // -----------------------------------------
    // Internal interface (extensible) - similar to protected
    // -----------------------------------------

    function checkPhase() internal view returns(int8) {
        for (uint8 i = 0; i < phases.length; ++i) {
            if (block.timestamp <= phases[i].closingTime && block.timestamp >= phases[i].openingTime) {
                return int8(i);
            }
        }
        
        return -1;
    } 

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
