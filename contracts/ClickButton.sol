pragma solidity ^0.4.9;


contract ClickButton {

    uint RoundTip = 0;
    uint EventTip = 0;

    struct PointerEvent {
        uint id;
        uint index;
        uint round;
        uint x;
        uint y;
        uint buttonmask;
    }

    struct Round {
        uint id;
        string reward;
        mapping(uint => PointerEvent) eventByIndex;
    }

    mapping(uint => Round) RoundById;
    mapping(uint => PointerEvent) EventById;

    string[] storedData;
    string[] storedScore;

    function SaveReward(uint roundId, string reward) {
        Round _round = RoundById[roundId];
        _round.id = roundId;
        _round.reward = reward;
    }

    function SaveEvent(uint roundId, uint eventIndex, uint x, uint y, uint mask) {
        Round _round = RoundById[roundId];
        EventTip = EventTip + 1;
        if (roundId > RoundTip) {
            RoundTip =RoundTip + 1;
        }
        _round.id = roundId;
        PointerEvent _event = _round.eventByIndex[eventIndex];
        _event.id = EventTip;
        _event.index = eventIndex;
        _event.round = roundId;
        _event.x = x;
        _event.y = y;
        _event.buttonmask = mask;
        EventById[EventTip] = _event; 
    }

    function GetRound(uint _roundId) constant returns (uint roundId, uint eventCount, string reward, uint totalRounds) {
        Round storage _round = RoundById[_roundId];

        return (
            _round.id,
            EventTip,
            _round.reward,
            RoundTip
        );
    }

    function GetEventForRound(uint _roundId, uint _eventIndex) constant returns (uint roundId, uint eventCount, uint eventId, uint x, uint y, uint buttonmask) {
        Round storage _round = RoundById[_roundId];
        PointerEvent _event = _round.eventByIndex[_eventIndex];
        return (
            _round.id,
            EventTip,
            _event.id,
            _event.x,
            _event.y,
            _event.buttonmask
        );
    }

    function GetEventById(uint _eventId) constant returns (uint roundId, uint eventCount, uint eventId, uint x, uint y, uint buttonmask) {
        PointerEvent _event = EventById[_eventId];
        return (
            _event.round,
            EventTip,
            _event.id,
            _event.x,
            _event.y,
            _event.buttonmask
        );
    }
    
    function GetInfo() constant returns (uint TotalRounds, uint TotalEvents){
        return (
            RoundTip,
            EventTip
        );
    }
}