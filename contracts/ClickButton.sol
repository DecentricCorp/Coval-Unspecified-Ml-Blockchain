pragma solidity ^0.4.9;

contract ClickButton {

    uint SessionTip = 0;
    uint RoundTip = 0;

    struct PointerEvent {
        bool Locked;
        uint Id;
        uint X;
        uint Y;
        uint Buttonmask;
    }
    
    struct Round {
        bool Locked;
        uint Id;
        uint Reward;
        uint EventTip;
        mapping(uint => PointerEvent) EventByIndex;
        bytes32 Agent;
    }

    mapping(uint => mapping(uint => Round)) RoundBySession;

    function getInfo() constant public returns (uint totalSessions, uint totalRounds) {
        return (SessionTip, RoundTip);
    }
    
    function saveReward(uint roundIndex, uint reward) public {
        // reward amount has been turned from a decimal to a bigint
        // 1.0 == 1000000, 0.5 == 500000, 0.01 == 10000
        Round memory _round = RoundBySession[SessionTip][roundIndex];
        //assert(!_round.Locked);
        _round = roundLocking(_round);
        _round.Locked = true;
        _round.Id = roundIndex;
        _round.Reward = reward;
        RoundBySession[SessionTip][roundIndex] = _round;
    }

    function saveEvent(uint roundIndex, uint x, uint y, uint buttonmask) public {
        handleSessionEnumeration(roundIndex);
        Round storage _round = RoundBySession[SessionTip][roundIndex];
        _round.Id = roundIndex;
        PointerEvent memory _event = _round.EventByIndex[_round.EventTip];
        _event = eventLocking(_event);
        _event.Id = _round.EventTip;
        _event.X = x;
        _event.Y = y;
        _event.Buttonmask = buttonmask;
        _round.EventTip = _round.EventTip + 1;
        _round.EventByIndex[_round.EventTip - 1] = _event;
        RoundBySession[SessionTip][roundIndex] = _round;
    }

    function getRoundByRound(uint roundIndex) public constant returns(uint id, uint reward, uint count, uint eventCount, bool writeLocked) {
        Round storage _round = RoundBySession[SessionTip][roundIndex];
        return (_round.Id, _round.Reward, RoundTip, _round.EventTip, _round.Locked);
    }

    function getEventByRound(uint roundIndex, uint eventIndex) public constant returns(uint id, uint x, uint y, uint buttonmask, uint count, bool writeLocked) {
        Round storage _round = RoundBySession[SessionTip][roundIndex];
        PointerEvent storage _event = _round.EventByIndex[eventIndex];
        return (_event.Id, _event.X, _event.Y, _event.Buttonmask, _round.EventTip, _event.Locked);        
    }

    function handleSessionEnumeration(uint roundIndex) internal {
        // if round < roundtip we have a new session
        if (roundIndex < RoundTip) {
            SessionTip = SessionTip + 1;
        }
    }

    function eventLocking(PointerEvent _event) internal returns(PointerEvent) {
        assert(!_event.Locked);
        _event.Locked = true;
        return _event;
    }

    function roundLocking(Round _round) internal returns(Round) {
        assert(!_round.Locked);
        _round.Locked = true;
        return _round;
    }

}