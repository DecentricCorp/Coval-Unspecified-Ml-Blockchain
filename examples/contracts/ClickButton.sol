pragma solidity ^0.4.9;


contract ClickButton {

    uint RoundTip = 0;

    struct PointerEvent {
        uint id;
        uint x;
        uint y;
        uint buttonmask;
    }

    struct Round {
        uint id;
        string reward;
        uint eventCount;
        mapping(uint => PointerEvent) events;
    }

    mapping(uint => Round) RoundById;

    string[] storedData;
    string[] storedScore;

    function SaveReward(uint roundId, string reward) {
        RoundById[roundId].reward = reward;
    }

    function SaveEvent(uint roundId, uint eventId, uint x, uint y, uint mask) {
        RoundById[roundId].id = roundId;
        RoundById[roundId].eventCount = eventId + 1;
        RoundById[roundId].events[eventId].id = eventId;
        RoundById[roundId].events[eventId].x = x;
        RoundById[roundId].events[eventId].y = y;
        RoundById[roundId].events[eventId].buttonmask = mask;        
    }

    function GetRound(uint _roundId) constant returns (uint roundId, uint eventCount) {
        Round storage _round = RoundById[roundId];

        return (
            _round.id,
            _round.eventCount,
            _round.reward
        );
    }

    function GetEvent(uint _roundId, uint _eventId) constant returns (uint roundId, uint eventCount, uint eventId, uint x, uint y, uint buttonmask) {
        Round storage _round = RoundById[roundId];
        PointerEvent _event = _round.events[_eventId];
        return (
            _round.id,
            _round.eventCount,
            _event.id,
            _event.x,
            _event.y,
            _event.buttonmask
        );
    }

    function set(string action, string score) {
        storedData.push(action);
        storedScore.push(score);
    }

    function get(uint i) constant returns (string y, string score) {
        return (storedData[i], storedScore[i]);
    }
}