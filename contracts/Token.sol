pragma solidity ^0.4.9;

import "Owned.sol";
import "Versioned.sol";
import "Interface.Token.sol";

contract Token is IToken, Owned, Versioned {
  uint256 public totalSupply;
  uint256 public decimals;
  mapping (address => uint256) public balances;
  mapping (address => mapping(address => uint256)) allowed;
  bytes32 public name;
  bytes32 public symbol;

  function Token() {
    var owner = msg.sender;
    var version = '0.2.1'; 
    var totalSupply = 0;
    TokenCreated(owner);
  }


  function mint(address _owner, uint256 _amount)  {
    totalSupply += _amount;
    balances[_owner] += _amount;
    TokenMinted(_owner, _amount);
  }

  function setDecimals(uint256 _d) constant onlyowner { decimals = _d;}
  function setName(bytes32 _n) onlyowner { name = _n; }
  function setSymbol(bytes32 _s) onlyowner { symbol = _s; }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if ( (balances[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (_value > 0) ) {
      balances[_from] -= _value;
      balances[_to] += _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    }
    else {
      return false;
    }
  }

  event OwnerTransfer(address indexed _owner, address indexed _from, address indexed _to, uint256 _value);
  function ownerTransfer(address _from, address _to, uint256 _value) returns (bool success) {
    if ( (balances[_from] >= _value) && (msg.sender == owner) && (_value > 0) ) {
      balances[_from] -= _value;
      balances[_to] += _value;
      OwnerTransfer(msg.sender, _from, _to, _value);
      return true;
    }
    else {
      return false;
    }
  }
  
  event OwnerTransferFrom(address indexed _owner, address indexed _from, address indexed _to, uint256 _value);
  function ownerTransferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if ( (allowed[_from][msg.sender] >= _value) && (msg.sender == owner) && (_value > 0) ) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      allowed[_from][msg.sender] -= _value;
      OwnerTransferFrom(msg.sender, _from, _to, _value);
      return true;
    }
    else {
        return false;
    }
  }


  function approve(address _spender, uint256 _value) returns (bool success) {
    if(allowed[msg.sender][_spender] + _value > allowed[msg.sender][_spender]) {
      allowed[msg.sender][_spender] += _value;
      Approved(msg.sender, _spender, _value);
      return true;
    }
    else {
      return false;
    }
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function unapprove(address _spender) returns (bool success) {
    allowed[msg.sender][_spender] = 0;
    Unapproved(msg.sender, _spender);
    return true;
  }
  event TokenCreated(address indexed _owner);
  event TokenMinted(address indexed _owner, uint256 _amount);
}
