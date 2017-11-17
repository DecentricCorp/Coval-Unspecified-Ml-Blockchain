pragma solidity ^0.4.9;
import "Coval.storage.sol";
import "Interface.Token.sol";

contract WrapsToken {
    
    address public tokenAddress;
    
    function WrapsToken() {

    }
    
    function Loaded() returns (bool isLoaded) {
        return true;
    }
    event TokenContractLoaded(address, string);
    
    function setToken(address _address) public returns (address _tokenAddress) {
        TokenContractLoaded(_address, "");
        tokenAddress = _address;
        return tokenAddress;
    }
    function TokenContract() internal constant returns (IToken token) {
        return IToken(tokenAddress);
    }
    
    function TokenMint(address _destinationAddress, uint _amount) internal {
        TokenContract().mint(_destinationAddress, _amount);
    }
    
    function TokenBalance(address _account) internal constant returns (uint balance) {
        return TokenContract().balanceOf(_account);
    }
}