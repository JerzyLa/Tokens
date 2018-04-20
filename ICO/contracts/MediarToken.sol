pragma solidity ^0.4.21;

import "./ERC223/ERC223_token.sol";

contract MediarToken is ERC223Token {

    string public constant name = "Mediar";
    string public constant symbol = "MED";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function MediarToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        bytes memory empty;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY, empty);
    }
}