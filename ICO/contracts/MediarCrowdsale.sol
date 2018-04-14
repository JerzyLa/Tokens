pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

// ----------------------------------------------------------------------------
// Crowdsale contract is used for selling ERC20 tokens for setup price.
// Below points describes rules for distributing tokens by this contract.
//      1. Sale is only available during certain period of time called phase.
//         There will be only 4 phases during whole ICO distribution.
//      2. Price for single token will be constatn during phase. Every next phase 
//         will start with higher price for token. Price in ethereum for single token will be
//         calculated before every transaction according to current exchange rate
//      3. At the end of final phase all unsold tokens will be distributed among
//         token owners. Addresses which will have more tokens will receive 
//         proportionally more unsold tokens. (Probably addresses with marginal 
//         amount of tokens will not take part in final token distribution) 
//      4. After final phase there will not be possible to buy more tokens. 
//         Payable functions will be disabled.
//      5. What is set goal ? Withdrawl when goal not reached, withdrawl when goal is reached ?
// ----------------------------------------------------------------------------
contract MediarCrowdsale is Ownable {
    using SafeMath for uint256;

    struct Phase {
        uint priceInEther;
        uint startTime;
        uint durationInMinutes;
        uint deadline;
    }

    enum State { Active, Suspend, Closed }

    ERC20 public tokenAddress;
    uint public collectedAmountInEther;
    State public state;
    Phase[4] phases;
    uint8 currentPhase;

    event TokenPurchased(address follower, uint amount, uint tokens);

    function Crowdsale (
        address ercTokenAddress, 
        uint price1,
        uint startTime1,
        uint duration1,
        uint price2,
        uint startTime2,
        uint duration2,
        uint price3,
        uint startTime3,
        uint duration3,
        uint price4,
        uint startTime4,
        uint duration4
        ) public
    {
        tokenAddress = ERC20Interface(ercTokenAddress);
        collectedAmountInEther = 0;
        state = State.Suspend;
        phases[0] = Phase(price1, startTime1, duration1 * 1 minutes, startTime1 + duration1 * 1 minutes);
        phases[1] = Phase(price2, startTime2, duration2 * 1 minutes, startTime2 + duration2 * 1 minutes);
        phases[2] = Phase(price3, startTime3, duration3 * 1 minutes, startTime3 + duration3 * 1 minutes);
        phases[3] = Phase(price4, startTime4, duration4 * 1 minutes, startTime4 + duration4 * 1 minutes);
    }

    function () payable public {
        updateState();
        require(state == State.Active);
        uint amountInEther = msg.value; 
        collectedAmountInEther += amountInEther;
        uint tokens = amountInEther / phases[currentPhase].priceInEther; // TODO: add safe math and price calculation
        tokenAddress.transfer(msg.sender, tokens);
        emit TokenPurchased(msg.sender, amountInEther, tokens);
    } 

    function updateState() private {
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

    function checkPhase() public constant returns(int8) {
        if (now < phases[0].startTime || now > phases[3].deadline)
            return -1;

        for (uint8 i = 0; i < phases.length; ++i) {
            if (now <= phases[i].deadline && now >= phases[i].startTime) {
                return int8(i);
            }
        }
        
        return -1;
    } 
}
