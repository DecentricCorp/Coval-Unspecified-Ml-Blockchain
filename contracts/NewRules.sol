pragma solidity ^0.4.7;
import "RuleChainPOC.sol";

contract NewRules {
    
    struct createdContract {
        address contractAddress;
    }
    function NewRulechain() public returns (address) {
        return address(new RuleChainPOC());
        
    }
}