pragma solidity ^0.4.9;

import "Interface.Contract.sol";

library Model {
    
    enum RecordType { Deposit, Mint, Transfer, User }
    
    struct DepositCollector {
        uint[] Deposits;
    }
    struct Deposit {
        uint Id;
        bytes32 BurnTransaction;
        bytes32 SignatureChallenge;
        bytes32 TransactionId;
        uint SenderId;
        uint RecipientId;
        uint Amount;
        bool Minted;
    }
    struct MintCollector {
        uint[] Mints;
    }
    struct Mint {
        uint Id;
        uint RecipientId;
        uint Amount;
        bool Claimed;
    }
    struct TransferCollector {
        uint[] Transfers;
    }
    struct Transfer {
        uint Id;
        uint SenderId;
        uint RecipientId;
        uint Amount;
        bool Claimed;
    }
    struct UserCollector {
        uint[] Users;
    }
    struct User {
        uint Id;
        bytes32 BtcAddress;
        address EthAddress;
        bool Claimed;
    }
    struct ContractCollector {
        uint[] Contracts;
    }
    struct Contract {
        uint Id;
        address Address;
    }
    struct RecordCollector {
        uint[] Records;
    }
    struct Record {
        uint Id;
        RecordType Type;
        
    }
    
}