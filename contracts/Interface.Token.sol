pragma solidity ^0.4.7;

contract IToken {
  //function totalSupply() constant returns (uint256 supply) {}
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function tranferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function ownerTransferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance (address _owner, address _spender) constant returns (uint256 remaining) {}
  function unapprove(address _spender) returns (bool success) {}
  function mint(address _destinationAddress, uint _amount) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approved(address indexed _owner, address indexed _spender, uint256 _value);
  event Unapproved(address indexed _owner, address indexed _spender);
}