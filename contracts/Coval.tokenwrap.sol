pragma solidity ^0.4.9;
import "Coval.storage.sol";
import "Interface.Token.sol";

contract WrapsToken {
    
    address public tokenAddress;
    
    function WrapsToken(){}
    
    function Loaded() returns (bool){
        return true;
    }
    event TokenContractLoaded(address, string);
    
    function setToken(address _address) public returns (address) {
        TokenContractLoaded(_address, "");
        tokenAddress = _address;
        var done = Loaded();
        return tokenAddress;
    }
    function TokenContract() internal constant returns (IToken) {
        return IToken(tokenAddress);
    }
    
    function TokenMint(address _destinationAddress, uint _amount) internal {
        TokenContract().mint(_destinationAddress, _amount);
    }
    
    function TokenBalance(address _account) internal constant returns (uint) {
        return TokenContract().balanceOf(_account);
    }
}