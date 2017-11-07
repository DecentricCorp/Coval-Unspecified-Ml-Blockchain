pragma solidity ^0.4.7;

import "Coval.tokenwrap.sol";
import "Coval.external.sol";

contract Controlled is ExternallyStored, WrapsToken {
    address emptyAddress = 0x0000000000000000000000000000000000000000000000000000000000000000;

    function CovalController() { }
    
    function AddUser(bytes32 _btcAddress, address _ethAddress) returns (uint id, uint totalRecords, bytes32 btcAddress, address ethAddress, bool claimed) {
        var _id = StorageContract().addUser(_btcAddress, _ethAddress);
        return GetUser(_id);
    }
    function GetUser(uint _id) constant returns (uint id, uint totalRecords, bytes32 btcAddress, address ethAddress, bool claimed) {
        return StorageContract().getUser(_id);
    }
    function GetUser(bytes32 _btcAddress) constant returns (uint id, uint totalRecords, bytes32 btcAddress, address ethAddress, bool claimed) {
        return StorageContract().getUser(_btcAddress);
    }
    
    function Mint(bytes32 _destinationAddress, uint _amount) {
        uint id;
        uint total;
        bytes32 btcAddress;
        address ethAddress;
        bool claimed;
        (id, total, btcAddress, ethAddress, claimed) = StorageContract().getUser(_destinationAddress);
        if (ethAddress == emptyAddress) {
            ethAddress = StringToAddress(_destinationAddress);
            StorageContract().addUser(_destinationAddress, ethAddress);
        }
        TokenMint(ethAddress, _amount);
    }
    
    function Mint(address _destinationAddress, uint _amount) {
        // take btc address as input
        // lookup user
        // create temp user if none exists
        TokenMint(_destinationAddress, _amount);
    }

    function StringToAddress(bytes32 btc) internal constant returns (address generatedAddress) {
        uint160 hash = uint160(sha256(btc));
        return hash;
    }
    
}