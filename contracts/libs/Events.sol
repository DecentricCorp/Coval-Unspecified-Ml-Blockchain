pragma solidity ^0.4.7;

contract Eventable {
    event Log(string _msg, uint _value);
    event LogString(string _msg, string _value);
    event Log32(string _msg, bytes32 _value);
    event LogBigInt(string _msg, uint256 _value);
    event LogArr(string _msg, uint[] _value);
    event Success(string _msg, bool _wasSuccess);
    event LogArr32(string _msg, bytes32[] _value);
}