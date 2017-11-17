pragma solidity ^0.4.7;

import "Versioned.sol";
import "Coval.controller.sol";

contract Coval is Controlled {
    
    function Coval() { 
        
    }

    function getStorage() public constant returns (address _storageAddress) {
        return storageAddress;
    }

    function getToken() public constant returns (address _tokenAddress) {
        return tokenAddress;
    }
}