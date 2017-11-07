pragma solidity ^0.4.9;

contract Sample {
    uint storedData;

    function set(uint x) {
        storedData = x;
    }

    function get() constant returns (uint x) {
        return storedData;
    }
}