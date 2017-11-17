pragma solidity ^0.4.10;

contract Invest {
    // total amount invested
    uint public invested = 0;
    
    // stores the last ping of every participants
    mapping (address => uint) public lastPing;
    // stores the last time a participant invested
    mapping (address => uint) public lastInvest;
    // stores the balance of each participant
    mapping (address => uint) public balanceOf;
    // stores the side balance of each participant
    mapping (address => uint) public sideBalanceOf;
    
    
    // when a user calls idle or invest
    event Pinged(address a, uint time);
    
    // when a user's balance increases
    // (after invest() or collectSideBalance())
    event Invested(address a, uint x);
    
    // when a user's balance decreases 
    // (after divest() or poke())
    event Divested(address a, uint x);
    
    // when a new reward is created at index i
    event NewReward(uint i);

    // A reward contains an amount that can be claimed by players
    struct Reward {
        uint value;                         // the amount to be shared 
        uint creationTime;                  // creation time of the reward
        uint oldTotal;                      // total invested at the creation time
        mapping (address => bool) claimed;  // true when a participant has claimed
    }

    Reward[] public pendingRewards;
    uint public countRewards = 0;

    // This is the constructor whose code is
    // run only when the contract is created.
    function Invest() public {
    }
    
    
    
    /** Private functions */
    
    
    // increases the balance and updates the total invested amount
    function increaseBalance(address a, uint x) private {
        balanceOf[a] = balanceOf[a] + x;
        invested = invested + x;
        Invested(a, x);
        lastInvest[msg.sender] = now; 
    }
    
    // decreases the balance and updates the total invested amount
    function decreaseBalance(address a, uint x) private {
        require(balanceOf[a] >= x);
        balanceOf[a] = balanceOf[a] - x;
        invested = invested - x;
        Divested(a, x);
    }
    
    // creates a new reward that can be claimed by other users
    function createReward(uint x, uint oldTotal) private {
        Reward memory r = Reward(x, now, oldTotal);
        
        pendingRewards[countRewards] = r;
        NewReward(countRewards);
        countRewards = countRewards + 1;
    }
    
    // removes a reward from the pending rewards
    function removeReward(uint i) private {
        require(i < countRewards);
        
        delete pendingRewards[i];
        
        if (i < countRewards - 1) {
            pendingRewards[i] = pendingRewards[countRewards - 1];
            delete pendingRewards[countRewards - 1];
        }
        
        countRewards = countRewards - 1;
    }
    
    
    
    /** Public functions */
    
    // to be called every day
    function idle() {
        lastPing[msg.sender] = now;
        Pinged(msg.sender, now);
    }
    
    // function called when a user wants to invest in the contract
    // after calling this function you cannot claim past rewards
    function invest() payable {
        lastPing[msg.sender] = now; 
        Pinged(msg.sender, now);
        increaseBalance(msg.sender, msg.value);
    }
    
    // function called when a user wants to divest
    function divest(uint256 x) {
        decreaseBalance(msg.sender, x);
        msg.sender.transfer(x);
    }
    
    // claims reward at index i
    // * each participant can take a cut from a reward only once
    // * the cut is proportional to the investment with respect to the 
    //    total investment at the creation time of the reward
    // * the funds go to a side balance that can be collected later on
    // * a reward can be claimed only by participants who have not invested
    //    after the creation time of the reward
    function claimReward(uint i) {
        require(
            !pendingRewards[i].claimed[msg.sender] && 
            pendingRewards[i].creationTime >= lastInvest[msg.sender]
        );
        
        pendingRewards[i].claimed[msg.sender] = true;
        uint v = pendingRewards[i].value * balanceOf[msg.sender] / pendingRewards[i].oldTotal;
        sideBalanceOf[msg.sender] = sideBalanceOf[msg.sender] + v;
    }
    
    // transfer the funds from the side balance to the main balance
    // after calling this function you cannot claim past rewards
    function collectSideBalance() {
        uint v = sideBalanceOf[msg.sender];
        sideBalanceOf[msg.sender] = 0;
        increaseBalance(msg.sender, v);
    }
    
    // collect all the funds from an expired reward at index i
    // a reward expires 27 hours after its creation
    function collectExpiredReward(uint i) {
        require(now > pendingRewards[i].creationTime + 27 hours);
        
        uint v = pendingRewards[i].value;
        removeReward(i);
        
        sideBalanceOf[msg.sender] = sideBalanceOf[msg.sender] + v;
    }
    
    // computes the next loss of an address
    function losingAmount(address a) constant returns (uint tolose) {
        // ensures 0 <= tolose <= balance[a]
        
        return balanceOf[a] / 10;
    }
    
    // used to take create a reward from the funds of someone who has not
    // idled in the last 27 hours
    function poke(address a) {
      require(now > lastPing[a] + 27 hours);
      
      lastPing[a] = now;
      uint tolose = losingAmount(a);
      
      createReward(tolose, invested);
      decreaseBalance(a, tolose);
    }
}
 