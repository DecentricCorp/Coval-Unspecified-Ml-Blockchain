pragma solidity ^0.4.9;
import "Coval.storage.sol";

contract ExternallyStored {
    
    address internal storageAddress;
    
    function ExternallyStored(){}
    
    function Loaded() returns (bool){
        return true;
    }
    event StorageContractLoaded(address, string);
    function setStorage(address _address) public returns (address) {
        StorageContractLoaded(_address, "");
        storageAddress = _address;
        var done = Loaded();
        return storageAddress;
    }
    /*function getStorage() public constant returns (address) {
        return storageAddress;
    }*/
    function StorageContract() internal constant returns (Storage) {
        return Storage(storageAddress);
    }
}