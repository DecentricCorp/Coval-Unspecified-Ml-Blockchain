pragma solidity ^0.4.9;

import "Coval.model.sol";
import "Owned.sol";
import "Versioned.sol";
import "Interface.Record.sol";
import "Interface.Contract.sol";
import "Interface.Plugin.sol";

contract Storage is Owned, Versioned {
    
    function Storage(){}
    
    uint depositTip = 0;
    uint transferTip = 0;
    uint userTip = 0;
    uint mintTip = 0;
    uint contractTip = 0;
    address emptyAddress = 0x0000000000000000000000000000000000000000000000000000000000000000;
    
    mapping (uint => Model.Deposit) public depositById;
    mapping (string => uint) depositIdByTxId;
    mapping (uint => Model.DepositCollector) depositsBySenderId;
    mapping (uint => Model.DepositCollector) depositsByRecipientId;
    
    mapping (uint => Model.Mint) public mintById;
    mapping (uint => Model.MintCollector) mintsByRecipientId;
    
    mapping (uint => Model.Transfer) public transferById;
    mapping (uint => Model.TransferCollector) transfersByRecipientId;
    mapping (uint => Model.TransferCollector) transfersBySenderId;
    
    mapping (uint => Model.User) public userById;
    mapping (uint => Model.UserCollector) usersByIndex;
    mapping (bytes32 => uint) userIdByBtc;
    mapping (address => uint) userIdByEth;
    
    enum Type { Plugin, Token, Storage }
    
    /*Generic Methods*/
    mapping (uint => Model.ContractCollector) contractsByType;
    mapping (uint => Model.Contract) contractById;
    mapping (bytes32 => uint) contractIdByName;
    
    mapping (uint => Model.RecordCollector) recordByType;
    mapping (uint => Model.Record) recordById;
    mapping (bytes32 => uint) recordIdByName;
    
    function addContract(Type _type, bytes32 _name, address _contractAddress) internal returns (bool) {
        contractTip += 1;
        contractIdByName[_name] = contractTip;
        contractById[contractTip] = Model.Contract(contractTip, _contractAddress);
        contractsByType[uint(_type)].Contracts.push(contractTip);
        return true;
    }
    function getContracts(Type _type) internal constant returns (uint[] Contracts) {
        return contractsByType[uint(_type)].Contracts;
    }
    function getContract(Type _type, uint _index) public constant returns (uint id, uint total, address _address) {
        var contractRecord = contractById[contractsByType[uint(_type)].Contracts[_index]];
        return (contractRecord.Id, contractsByType[uint(_type)].Contracts.length, contractRecord.Address);
    }
    function getContractByName(Type _type, bytes32 _name) public constant returns (uint id, uint total, address _address) {
        var contractRecord = contractById[contractIdByName[_name]];
        return (contractRecord.Id, contractsByType[uint(_type)].Contracts.length, contractRecord.Address);
    }
    /* Plugin */
    function addPlugin(bytes32 _name, address _contractAddress) returns (bool success) {
        return addContract(Type.Plugin, _name, _contractAddress);
    }
    function getPlugin(uint _index) constant returns (uint id, uint total, address _address) {
        return getContract(Type.Plugin, _index);
        
    }
    function getPluginByName(bytes32 _name) constant returns(uint id, uint total, address _address) {
        return getContractByName(Type.Plugin, _name);
    }
    /* User */
    function addUser(bytes32 _btcAddress, address _ethAddress) returns (uint userId) {
        var userCheck = userExists(_btcAddress, _ethAddress);
        if (userCheck > 0) {
            return userCheck;
        }
        userTip += 1;
        userById[userTip] = Model.User(userTip, _btcAddress, _ethAddress, false);
        userIdByBtc[_btcAddress] = userTip;
        userIdByEth[_ethAddress] = userTip;
        return userTip;
    }
    function userExists(bytes32 _btcAddress, address _ethAddress) returns (uint id) {
        var eth = userById[userIdByEth[_ethAddress]];
        if (eth.EthAddress != emptyAddress ) {
            return eth.Id;
        }
        return 0;
    }
    function getUser(uint _index) constant returns (uint id, uint totalRecords, bytes32 btcAddress, address ethAddress, bool claimed) {
        var user = userById[_index];
        return (user.Id, userTip, user.BtcAddress, user.EthAddress, user.Claimed);
    }
    function getUser(bytes32 _btcAddress) constant returns (uint id, uint totalRecords, bytes32 btcAddress, address ethAddress, bool claimed) {
        var user = userById[userIdByBtc[_btcAddress]];
        return (user.Id, userTip, user.BtcAddress, user.EthAddress, user.Claimed);
    }
    /* Deposit */
    function addDeposit(bytes32 burnTx, bytes32 sig, bytes32 txId, bytes32 _sender, bytes32 _recipient, uint _amount) returns(address ethAddress, uint amount) {
        depositTip += 1;
        var deposit = Model.Deposit(depositTip, burnTx, sig, txId, userIdByBtc[_sender], userIdByBtc[_recipient], _amount, false);
        depositById[depositTip] = deposit;
        depositsBySenderId[userIdByBtc[_recipient]].Deposits.push(depositTip);
        depositsByRecipientId[userIdByBtc[_sender]].Deposits.push(depositTip);
        return (userById[userIdByBtc[_recipient]].EthAddress, _amount);
    }
    /* Mint */
    function addMint(bytes32 _recipientId, uint _amount, bool seen) returns(address ethAddress, uint amount) {
        mintTip += 1;
        // register temp if unknown recipient
        var mint = Model.Mint(mintTip, userIdByBtc[_recipientId], _amount, seen);
        mintById[mintTip] = mint;
        mintsByRecipientId[userIdByBtc[_recipientId]].Mints.push(mintTip);
        return (userById[userIdByBtc[_recipientId]].EthAddress, _amount);
    }
    /* Transfer */
    function addTransfer(bytes32 _senderId, bytes32 _recipientId, uint _amount) returns(address ethAddress, uint amount) {
        transferTip += 1;
        var transfer = Model.Transfer(transferTip, userIdByBtc[_senderId], userIdByBtc[_recipientId], _amount, false);
        transferById[transferTip] = transfer;
        transfersByRecipientId[userIdByBtc[_recipientId]].Transfers.push(transferTip);
        transfersBySenderId[userIdByBtc[_senderId]].Transfers.push(transferTip);
        return (userById[userIdByBtc[_recipientId]].EthAddress, _amount);
    }
}