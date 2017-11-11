pragma solidity ^0.4.7;

contract IToken {
  //function totalSupply() constant returns (uint256 supply) {}
  function balanceOf(address) constant returns (uint256) {}
  function transfer(address, uint256) returns (bool) {}
  function tranferFrom(address, address, uint256) returns (bool) {}
  function ownerTransferFrom(address, address, uint256) returns (bool) {}
  function approve(address, uint256) returns (bool) {}
  function allowance (address, address) constant returns (uint256) {}
  function unapprove(address) returns (bool) {}
  function mint(address, uint) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approved(address indexed _owner, address indexed _spender, uint256 _value);
  event Unapproved(address indexed _owner, address indexed _spender);
}