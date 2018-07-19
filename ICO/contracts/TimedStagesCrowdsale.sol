pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ERC223/ERC223_Interface.sol";
import "./ERC223/Receiver_Interface.sol";

/**
  * @title TimedStagesCrowdsale
  */
contract TimedStagesCrowdsale is ContractReceiver {
  using SafeMath for uint256;

  struct Stage {
    uint256 rate;
    uint256 minInvest;
    uint256 openingTime;
    uint256 closingTime;
  }

  // The token being sold
  ERC223 public token; 
  
  // Address where funds are collected
  address public wallet;

  // Amount of wei collected
  uint256 public collectedAmountInWei;

  // Crowdsale stages
  Stage[] public stages;

  // List of investors
  address[] public investors;

  // How much ETH each address has invested to this crowdsale
  mapping(address => uint256) public investedAmountOf;

  address public oldCrowdsale;

  /**
  * Event for token purchase logging
  * @param investor who bought tokens
  * @param value weis paid for purchase
  * @param amountOfTokens amount of tokens purchased
  */
  event TokenPurchase(address indexed investor, uint256 value, uint256 amountOfTokens);

  modifier onlyWhileOpen() {
    require(checkStage() >= 0);
    _;
  }

  constructor(address _oldCrowdsale) public {
    require(_oldCrowdsale != address(0));

    oldCrowdsale = _oldCrowdsale;
    wallet = TimedStagesCrowdsale(oldCrowdsale).wallet();
    token = TimedStagesCrowdsale(oldCrowdsale).token();
    collectedAmountInWei = TimedStagesCrowdsale(oldCrowdsale).collectedAmountInWei();

    // investors which already took part in crowdsale
    investors.push(0x5CF41F92dBe726Bb5Addc09baD6e8F1c69CC3E2f);
    investors.push(0xcBf22E891202c90af8bd1cB8a37A9FD1338AD487);
    investors.push(0x54B05C7ec94a9CB8E99762C31EB78824FD5eeFbB);
    investors.push(0xf35A262AB1cf4Fe86ff9E9f03199226b81F6530B);
    investors.push(0xf7e4c1F7EB733E4C0f6B0059BabD4a3d258FD476);
    investors.push(0x3D0eBf06F04BAB909AF3Ae42e1aAEAe474687562);
    investors.push(0xcA39e1399e07F33Df3F18cd481B6B4939e6a6bC4);
    investors.push(0x286eE3f8528b4dCfb91E59b5ED3B60033a11CAb9);
    investors.push(0x6afF0f23aC5130da27c6898620724c81e652993F);
    investors.push(0x4D68289E7f3B823B877275B3745d437c38A9b653);
    investors.push(0xbA7f3995432D5Eb881E2CDd7ddfa454f4765CD85);
    investors.push(0x7676BeCEAac651F8489431C82Ecb17B0906BE884);
    investors.push(0x4f953b6b0a9e990382dc169e21761127826627D1);
    investors.push(0x8c8b167504911f7EdC4f4F9277B27082CBDd9A2b);
    investors.push(0xA0bD339989a4Aba8503fa05578B61c8E8543E27d);
    investors.push(0x3C7e7661a76e03Bf16fB1C1DE18CEDD673eAfabf);
    investors.push(0x3015985AE5198CAc18CbbB167F8dc7Ad2733F2EC);
    investors.push(0xca071536c54Faf8cFCB0F7b22e5a91ed48ED2cEe);
    investors.push(0xa0C50BA04F028AEa547fde6Eb41437A0B1bB8961);
    investors.push(0x6c16fC079a146b2Da93FE20f91c848a6C9829b9a);
    investors.push(0x9b9Bd897fdCbBAdA3EF755Da642Ed6711f2f4171);
    investors.push(0xdE3012c05a93226a82517Cc73DF33324946cA8F7);
    investors.push(0xd9aE272a6a34546504317995Dd337b189704D94f);
    investors.push(0x7071F121C038A98F8A7d485648a27FCD48891Ba8);
    investors.push(0x09871639c2D59E81B4eA16dc24b46Bc1e7321601);
    investors.push(0x257ECf53Bee1893Dc54262aAd29b9CF04520529F);
    investors.push(0xbAd06d566d296973176048dCa00A0581f2f9585C);
    investors.push(0x2835eBB9767B391c8b5e15Bbe4164E0a86d3d0B2);
    investors.push(0x3B2a085375193e9DfE004161eA3Ba0d282Aa0344);
    investors.push(0x1B88C415863e7CC830348d5BAAd13ea6730e45f1);

    // update invested amount of wei
    for(uint i = 0; i < investors.length; ++i) {
      address investor = investors[i];
      // TODO: fix this
      // investedAmountOf[investor].add(PostDeliveryCrowdsale(oldCrowdsale).shares(investor));
    }
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /*
   * @dev For ERC223 support
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

    if(investedAmountOf[msg.sender] == 0) {
      // Add new investor
      investors.push(msg.sender);
    }

    // update investor
    investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(amountInWei);

    // update total
    collectedAmountInWei = collectedAmountInWei.add(amountInWei);

    // assign tokens
    uint256 tokens = amountInWei.mul(stages[stageNumber].rate);
    _tokenPurchase(msg.sender, tokens);
//    _postponedTokenPurchase(msg.sender, amountInWei);
    emit TokenPurchase(msg.sender, amountInWei, tokens);

    // forward to wallet
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
}
