pragma solidity ^0.4.7;

import "libs/Events.sol";

/* Eventable Pulls in Event methods */
contract Modified is Eventable {
    bool canExecute = true;
    bool allowExecution = false;
    uint _step;
    bool precheck = true;
    
    /* Disable precheck*/
    modifier disablepre {
        precheck = false;
        _;
    }
    
    /* Initializes a new rule chain clearing any state */
    modifier init(string _msg) {
        resetExecutionState();
        Log(_msg, 0);
        _;
    }
    
    /* Always allow */
    modifier allow {
        Log("In Allow modifier", _step++);
        if (baseModifier()) {
            canExecute = true;
            _;
        }
        resetExecutionState();
    }
    
    /* Always disallow */
    modifier disallow {
        Log("In Disallow modifier", _step++);
        if (baseModifier()) {
            if (true) //Halt!
                canExecute = false;
            _;
        }
        resetExecutionState();
    }
    
    /* Closes a rule chain and either allows execution or HALT's*/
    modifier resolve {
        if (Resolve("Final resolution of modifiers"))
            _;
        resetExecutionState();
    }
    
    /* Unused ? */
    modifier chained {
        if (baseModifier()) {
            _;
        }
    }
    
    /* Logic for resolve rule [msg parameter is to illustrate logging] */
    function Resolve(string msg) internal returns (bool) {
        makeLogCallback(msg);
        Success("Continue?", canExecute);
        if (canExecute) {
            allowExecution = true;
            return true;
        }
        Log("Resolve HALT", _step++);
        return false;
    }
    
    /* Checks to see if the previous rule toggled the halt flag */
    function baseModifier() internal returns (bool) {
        if (!precheck)
            return true;
        return Resolve("Pre-check to see if should halt modifier evaluation");
    }
    
    /* More logging stuff */
    function makeLogCallback(string _msg) internal {
        Log(_msg, _step++);
    }
    
    /* Internal method to reset state */
    function resetExecutionState() internal {
        canExecute = true;
        precheck = true;
        allowExecution = false;
        _step = 0;
    }
 
}