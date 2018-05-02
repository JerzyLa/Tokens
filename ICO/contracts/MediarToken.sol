pragma solidity ^0.4.21;

import "./Tokens/AMLToken.sol";

contract MediarToken is AMLToken {

    uint256 public constant INITIAL_SUPPLY = 420000000 * (10 ** uint256(18));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function MediarToken() public 
        AMLToken("Mediar", "MDR", INITIAL_SUPPLY, 18) {
    }
}