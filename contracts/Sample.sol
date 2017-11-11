pragma solidity ^0.4.9;

contract Sample {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public constant returns (uint x) {
        return storedData;
    }
}