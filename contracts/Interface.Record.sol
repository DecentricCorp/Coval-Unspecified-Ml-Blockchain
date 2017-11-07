pragma solidity ^0.4.7;

contract IRecord {
    
    function IRecord(){}
    
    mapping(uint => bytes32) public idHashByIndex;
    
    function newId() returns (bytes32) {
        Id = Id+=1;
        bytes32 hash = sha3(Id);
        idHashByIndex[Id] = hash;
        return hash;
    }
    uint Id = 0;
}