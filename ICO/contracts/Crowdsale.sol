pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

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
contract Crowdsale is Owned
{
    ERC20Interface public tokenAddress;
    uint public price;
    uint public collectedAmount = 0;
    bool isCrowdsaleOpen = false;

    event FundTransfer(address follower, uint amount, uint tokens);

    function Crowdsale(
        address ercTokenAddress, 
        uint etherCostOfEachToken) public
    {
        tokenAddress = ERC20Interface(ercTokenAddress);
        price = etherCostOfEachToken * 1 ether;
        isCrowdsaleOpen = true; // temporary
    }

    function () payable public
    {
        require(isCrowdsaleOpen);
        uint amountInEther = msg.value; 
        collectedAmount += amountInEther;
        uint tokens = amountInEther / price; // TODO: add safe math
        tokenAddress.transfer(msg.sender, tokens);
        FundTransfer(msg.sender, amountInEther, tokens);
    } 
}