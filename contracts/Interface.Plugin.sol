pragma solidity ^0.4.7;

import "Interface.Contract.sol";
import "Interface.Record.sol";

contract IPlugin is IContract, IRecord {
    
    bool public initialized = false;
    string public PluginName;
    string public ContractName;
    string public Description;
    
    function Init() external returns (bool isInitialized) { 
        if (initialized) {
            return false;
        }
        _Init(); 
        return PostInit();
        
    }
    function _Init() internal returns (bool success) {

    }
    
    event Loaded(string, string, bool);
    function PostInit() internal returns (bool isReady) {
        initialized = true;
        Loaded("Plugin loading complete: ", PluginName, initialized);
        return Ready();
    }
    function DoWork(uint, bytes32[]) returns (bool success) {

    }
    function Ready() constant returns (bool isReady) {
        return initialized;
    }
}