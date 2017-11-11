pragma solidity ^0.4.9;

import "Interface.Plugin.sol";

contract Sample is IPlugin {
    
    function StringValidate() public {

    }
    
    function _Init() internal returns (bool success) {
        PluginName = "Sample";
        ContractName = "Plugin.Sample.sol";
        Description = "Used to demonstrate how a plugin is implemented";
        return true;
    }
    
    function DoWork(uint _methodId, bytes32[] _parameters) returns (bool workComplete) {
        // Operate logic here:
        // _methodId is an index reference to the method of interest
        // _parameters is an array of input parameters for the method specified
        return true; 
    }
    
}