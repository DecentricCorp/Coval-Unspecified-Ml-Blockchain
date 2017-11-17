pragma solidity ^0.4.9;

import "Interface.Plugin.sol";

contract StringValidate is IPlugin {
    
    
    function StringValidate() {
        
    }
    
    event LoadedPlugin(string, string, bool);

    function _Init() internal returns (bool loaded) {
        PluginName = "String Validate";
        ContractName = "Plugin.StringValidate.sol";
        Description = "Used for creating and validating Bitcoin based signatures";
        Loaded("String Validate", PluginName, initialized);
        return true;
    }
    
    function DoWork(uint _methodId, bytes32[] _parameters) returns (bool workComplete) {
        return true; 
    }
    
    function internal_createChallenge(string btc_from, string sep, string amount, string tail) internal constant returns (string challenge) {
        return strConcat(btc_from, sep, amount,tail, "");
    }
    function internal_ValidateBSM(string payload, address key, uint8 v, bytes32 r, bytes32 s) constant returns (bool isValid) {
        return key == ecrecover(internal_CreateBSMHash(payload), v, r, s);
    }
    function internal_CreateBSMHash(string payload) internal constant returns (bytes32 mshHash) {
        string memory prefix = "\x18Bitcoin Signed Message:\n";
        return sha256(
            sha256(prefix, bytes1(
                                bytes(payload).length
                            ), payload));
    }
    
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) { 
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }
}