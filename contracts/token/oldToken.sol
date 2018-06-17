pragma solidity ^0.4.11;

import "./erc20.sol";

// Interface of old ICX Token
/// @author Nour Haridy - <nour@lamarkaz.com>
contract oldTokenInterface is ERC20 {
  
    function allowance(address owner, address spender) constant returns (uint _allowance);

    function transferFrom( address from, address to, uint value) returns (bool success);

    function burnTokens(uint tokensAmount);

    function enableTokenTransfer();

}
