pragma solidity ^0.4.12;

import './lib/StandardToken.sol';

contract Moneto is StandardToken {
  
  string public name = "Moneto";
  string public symbol = "MTO";
  uint8 public decimals = 18;

  function Moneto(address saleAddress) public {
    require(saleAddress != 0x0);

    totalSupply = 42901786 * 10**18;
    balances[saleAddress] = totalSupply;
    Transfer(0x0, saleAddress, totalSupply);

    assert(totalSupply == balances[saleAddress]);
  }

  function burn(uint num) public {
    require(num > 0);
    require(balances[msg.sender] >= num);
    require(totalSupply >= num);

    uint preBalance = balances[msg.sender];

    balances[msg.sender] -= num;
    totalSupply -= num;
    Transfer(msg.sender, 0x0, num);

    assert(balances[msg.sender] == preBalance - num);
  }
}