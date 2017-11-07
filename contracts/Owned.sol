pragma solidity ^0.4.9;

contract Owned {
  string public version = '0.0.2';
  address public owner;
  function Owned() { owner = msg.sender; }
  function transferOwnership(address _new_owner) onlyowner {
    address currentOwner = owner;
    owner = _new_owner;
    OwnershipTransfer(currentOwner, _new_owner);
  }
  modifier onlyowner { if (msg.sender != owner) throw; _; }
  event OwnershipTransfer(address indexed _from, address indexed _to);
}
