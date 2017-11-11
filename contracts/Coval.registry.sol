pragma solidity ^0.4.9;

import "Coval.external.sol";

contract Registry is ExternallyStored {
    
    event Done(string);
    function Loaded() returns (bool) {
        Done("Registry Initialized");
        return true;
    }
    
    function AddPlugin(bytes32 _name, address _pluginAddress) returns (uint contractId, uint contractTotal, address contractAddress, bool success) {
        success = StorageContract().addPlugin(_name, _pluginAddress);
        var plugin = IPlugin(_pluginAddress);
        plugin.Init();
        (contractId, contractTotal, contractAddress) = GetPlugin(_name);
    }
    function GetPlugin(bytes32 _name) constant returns (uint contractId, uint contractTotal, address contractAddress) {
        (contractId, contractTotal, contractAddress) = StorageContract().getPluginByName(_name);
    }
    function GetPlugin(uint _id) constant returns (uint contractId, uint contractTotal, address contractAddress) {
        (contractId, contractTotal, contractAddress) = StorageContract().getPlugin(_id);
    }
    
}