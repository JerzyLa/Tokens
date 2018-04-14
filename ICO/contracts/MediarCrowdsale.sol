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
        uint256 startTime;
        uint256 durationInMinutes;
        uint256 deadline;
    }

    enum State { Active, Suspend, Closed }

    // The token being sold
    ERC20 public token;  // TODO: change token to ERC223 or different
    
    // Address where funds are collected
    address public wallet;

    // Amount of wei collected
    uint256 public collectedAmountInWei;

    // Crowdsale states 
    State state;
    uint8 currentPhase;
    Phase[4] phases;

   /**
    * Event for token purchase logging
    * @param purchaser who bought tokens
    * @param value weis paid for purchase
    * @param amountOfTokens amount of tokens purchased
   */
    event TokenPurchased(address buyer, uint256 value, uint256 amountOfTokens);

    modifier crowdsaleClosed() {
        require(state == State.Closed);
        _;
    }

    function Crowdsale (
        address _wallet,
        ERC20 _token, 
        uint256 _rate1, uint256 _startTime1, uint256 _duration1,
        uint256 _rate2, uint256 _startTime2, uint256 _duration2,
        uint256 _rate3, uint256 _startTime3, uint256 _duration3,
        uint256 _rate4, uint256 _startTime4, uint256 _duration4
        ) public
    {
        require(_price1 > 0);
        require(_price2 > 0);
        require(_price3 > 0);
        require(_price4 > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        wallet = _wallet;
        token = _token;
        state = State.Suspend;
        phases[0] = Phase(rate1, startTime1, duration1 * 1 minutes, startTime1 + duration1 * 1 minutes);
        phases[1] = Phase(rate2, startTime2, duration2 * 1 minutes, startTime2 + duration2 * 1 minutes);
        phases[2] = Phase(rate3, startTime3, duration3 * 1 minutes, startTime3 + duration3 * 1 minutes);
        phases[3] = Phase(rate4, startTime4, duration4 * 1 minutes, startTime4 + duration4 * 1 minutes);
    }

    
    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    // TODO: add crowdsale closed status
    // TODO: change phase 2
    function () external payable {
        updateState();
        require(state == State.Active);
        require(msg.value != 0);
        
        uint256 amountInWei = msg.value;
        uint256 tokens = amountInWei.mul(phases[currentPhase].rate); 
        collectedAmountInWei = collectedAmountInWei.add(amountInWei);

        token.transfer(msg.sender, tokens);
        emit TokenPurchased(msg.sender, amountInWei, tokens);
        forwardFunds(); // Czy to ma być, czy tylko na końcu transfer ?
    }

    function withdrawal() public view onlyowner crowdsaleClosed {

    }

    function refunding() public view onlyowner crowdsaleClosed {

    }

    // -----------------------------------------
    // Internal interface (extensible) - similar to protected
    // -----------------------------------------
    
    function updateState() internal {
        if (state == State.Active || state == State.Suspend) {
            int8 phase = checkPhase();
            if (phase < 0) {
                state = State.Suspend;
            } else {
                state = State.Active;
                currentPhase = uint8(phase);
            }
        }
    } 

    function checkPhase() internal constant returns(int8) {
        if (now < phases[0].startTime || now > phases[3].deadline)
            return -1;

        for (uint8 i = 0; i < phases.length; ++i) {
            if (now <= phases[i].deadline && now >= phases[i].startTime) {
                return int8(i);
            }
        }
        
        return -1;
    } 

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
