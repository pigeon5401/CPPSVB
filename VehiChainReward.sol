// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VehiChainReward {
    
    // Initialize TD address and reputation value thresholds
    constructor(int256 _reputationThreshold) {
        trustedAuthority = msg.sender;
        reputationThreshold = _reputationThreshold;
    }

    // Curb Unit List, which records all curb units and the utilization status of the curb units
    struct RoadSideUnitList {
        address rsuId; // RSU address
        bool state; // RSU availability
    }

    // Signature list, which records all signatures
    struct SigncryptionList {
        bytes32 signcryptionId; // The unique identifier for this signature
        bytes32 signcryption; // signcryption information
        int256 rewardvalue; // The rewards you get for signcryption
        bool state; // Whether or not the signcryption is valid
    }

    // Vehicle list added to VANETs, vehicle generated public-private key pair added when
    struct TrustedVehicleList {
        address vehiId; // Unique identification of vehicles
        int256 reputationvalue; // Reputational value of vehicles
        bool state; // Credibility of vehicles
    }

    // Road information list, storing the currently broadcasted road information
    struct BoardcastMessageList {
        bytes32 messageId;
        bytes32 signcryptionId; // corresponding signcryption
        bytes32 message;
        address rsuId;
        bool availability; // Availability of road information
    }

    address private trustedAuthority;
    int256 private reputationThreshold;
    mapping (address => RoadSideUnitList) private rsus;
    mapping (address => TrustedVehicleList) private trustedVehicles;
    mapping (bytes32 => SigncryptionList) private signcryptions;
    mapping (bytes32 => BoardcastMessageList) private boardcastMessages;

    event AddedRsuToList(address addr);
    event StorageSigncryption(bytes32 signcryptionId, bytes32 signcryption, bool state);
    event AddedBroadcastMessage(bytes32 messageId, bytes32 signcryptionId, address rsuId, bytes32 message);
    event RevokedBroadcastMessage(bytes32 messageId);
    event BannedVehi(address vehiId);
    event AddedIncentiveReputation(address vehiId, int256 rewardvalue);
    event StorageSigncryptionReward(bytes32 signcryptionId, int256 rewardvalue);

    modifier isRSU() {
        require(rsus[msg.sender].state, "Caller is not the RSU");
        _;
    }

    modifier isTD() {
        require(msg.sender == trustedAuthority, "Caller is not the TD");
        _;
    }

    function addRsuToList(address rsuId) external isTD{
        rsus[rsuId].rsuId = rsuId;
        rsus[rsuId].state = true;

        emit AddedRsuToList(rsuId);
    }

    function deleteRsuFromList(address rsuId) external isTD{
        delete rsus[rsuId];
    }

    function getRsu(address rsuId) external view isTD returns (address, bool) {
        return (rsus[rsuId].rsuId, rsus[rsuId].state);
    }

    // Storing Verified signcryption information
    function storageVerifiedSigncryption(bytes32 signcryptionId, bytes32 signcryption, bool state) external isRSU {
        signcryptions[signcryptionId].signcryptionId = signcryptionId;
        signcryptions[signcryptionId].signcryption = signcryption;
        signcryptions[signcryptionId].state = state;

        emit StorageSigncryption(signcryptionId, signcryption, state);
    }

    function getSigncryption(bytes32 signcryptionId) external view returns (bytes32, bool, int256) {
        return (signcryptions[signcryptionId].signcryption, 
            signcryptions[signcryptionId].state, 
            signcryptions[signcryptionId].rewardvalue);
    }

    // Broadcasting of road condition information sent by vehicles
    function broadcastMessage(bytes32 messageId, bytes32 message, bytes32 signcryptionId) external isRSU {
        boardcastMessages[messageId].messageId = messageId;
        boardcastMessages[messageId].rsuId = msg.sender;
        boardcastMessages[messageId].signcryptionId = signcryptionId;
        boardcastMessages[messageId].message = message;
        boardcastMessages[messageId].availability = true;

        emit AddedBroadcastMessage(messageId, signcryptionId, msg.sender, message);
    }

    // Setting specified road information as expired
    function expiredBroadcastMessage(bytes32 messageId) external isRSU {
        boardcastMessages[messageId].availability = false;

        emit RevokedBroadcastMessage(messageId);
    }

    function getMessage(bytes32 messageId) external view returns (address, bytes32, bytes32, bool) {
        return (boardcastMessages[messageId].rsuId,
            boardcastMessages[messageId].signcryptionId,
            boardcastMessages[messageId].message, 
            boardcastMessages[messageId].availability);
    }

    // Determining if a vehicle is trustworthy
    function isTrustedVehi(address vehiId) external view returns (bool, int256) {
        return (trustedVehicles[vehiId].state, trustedVehicles[vehiId].reputationvalue);
    }

    // Rewards for storing signcryption information
    function storageSigncryptionReward(bytes32 signcryptionId, int256 rewardvalue) external isTD {
        signcryptions[signcryptionId].rewardvalue = rewardvalue;

        emit StorageSigncryptionReward(signcryptionId, rewardvalue);
    }

    // Incentivize vehicles that provide information on road conditions
    function incentiveReputation(address vehiId, int256 rewardvalue) external isTD {
        trustedVehicles[vehiId].vehiId = vehiId;
        trustedVehicles[vehiId].reputationvalue += rewardvalue;

        emit AddedIncentiveReputation(vehiId, trustedVehicles[vehiId].reputationvalue);

        if (trustedVehicles[vehiId].reputationvalue < reputationThreshold) {
            delete trustedVehicles[vehiId];

            emit BannedVehi(vehiId);
        } else {
            trustedVehicles[vehiId].state = true;
        }
    }
}