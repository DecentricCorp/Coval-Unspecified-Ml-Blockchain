pragma solidity ^0.4.7;

contract IRecord {
    
    function IRecord() public {

    }
    
    mapping(uint => bytes32) public idHashByIndex;
    uint Id = 0;
    
    function newId() public returns (bytes32 _newId) {
        Id = Id += 1;
        bytes32 hash = sha3(Id);
        idHashByIndex[Id] = hash;
        return hash;
    }
    
}