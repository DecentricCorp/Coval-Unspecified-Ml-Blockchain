pragma solidity ^0.4.7;

import "libs/Modifiers.sol";
import "libs/RuledOver.sol";
import "Token.sol";

contract RuleChainPOC is RuledOver {
    uint _value;
    function RuleChainPOC() {
        Log("Inside Constructor", _value++);
    }
    
    /* DEPRECATED with addition of resolve modifier*/
    function Allowed() init("----------Allowed (bad)------------") allow {
        Log("Inside Allowed", _value++);
    }
    /* DEPRECATED with addition of resolve modifier*/
    function NotAllowed() init("---------Not Allowed (bad)---------") disallow {
        Log("Inside Not Allowed", _value++);
    }
    /* Using the always allow rule and the resolve rule we want to allow this execution*/
    function AllowedResolve() init("--------Allowed Resolve------") allow resolve {
        Log("Inside Allowed Resolve", _value++);
    }
    /* Using the never allow rule and the resolve rule we DO NOT want to allow this execution*/
    function NotAllowedResolve() init("-----Not Allowed Resolve-----") disallow resolve {
        Log("Inside Not Allowed Resolve", _value++);
    }
    /* Using the never allow rule followed by the allow rule we want to NOT ALLOW execution and 
       We also do not want the allow rule to be evaluiated because 1 fail in a rule chain means 
       the entire chain should fail so no need to keep wasting resources evaluating the rest of the rules
    */
    function HaltEarly() init("---------Halt Early---------") disallow allow resolve {
        Log("Inside Halt Early", _value++);
    }
    /* Using the disablepre rule we turn off the "failing once fails the whole chain" feature
       This both proves the "fail once" usecase works by expecting to incorrectly allow execution
       This also illustrates a new type of rule chain (last rule in the rule chain prior to resolve wins)
    */
    function HaltEarlyFail() init("---------Halt Early---------") disablepre disallow allow resolve {
        Log("Inside Halt Early Fail", _value++);
    }
    
    function createToken() returns (address) {
        Token token = new Token();
        uint value = token.assignRule("foo", true, "balancesOf", RuleType.MemberOf);
        var (name, allow) = token.getRule(0);
        //LogString("get name for 0", bytes32ToString(token.getRuleName(0)));
        //LogString("get name for 0", bytes32ToString(name));
        Log("foo rule added and returns", value);
        /*uint value2 = token.assignRule("bar", false, "balancesOf", RuleType.MemberOf);
        var (name, allow) = token.getRule(0);
        Log("foo rule added and returns", value);
        Log("bar rule added and returns", value2);
        LogString("get name for 0", bytes32ToString(name));
        LogString("get name for 1", bytes32ToString(token.getRuleName(1)));*/
    }
    
    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    function stringToBytes32(string memory source) constant returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
        
    }
}