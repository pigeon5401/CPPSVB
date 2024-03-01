// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VehiChainReward {
    
    // 初始化TA的地址和声誉值阈值
    constructor(int256 _reputationThreshold) {
        trustedAuthority = msg.sender;
        reputationThreshold = _reputationThreshold;
    }

    // 路边单元列表，记录了所有路边单元和路边单元的使用状态
    struct RoadSideUnitList {
        address rsuId; // RSU地址
        bool state; // RSU是否可用
    }

    // 签密列表，记录了所有签密数据
    struct SigncryptionList {
        bytes32 signcryptionId; // 这个签密的唯一标识
        bytes32 signcryption; // 签密信息
        int256 rewardvalue; // 这个签密获得的奖励
        bool state; // 签密是否有效
    }

    // 加入VANETs的车辆名单，车辆生成公私钥对的时候加入
    struct TrustedVehicleList {
        address vehiId; // 车辆的唯一标识
        int256 reputationvalue; // 车辆的声誉值
        bool state; // 车辆是否可信
    }

    // 路况信息列表，存储当前广播的路况信息
    struct BoardcastMessageList {
        bytes32 messageId;
        bytes32 signcryptionId; // 对应的签密
        bytes32 message;
        address rsuId;
        bool availability; // 路况信息是否可用
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

    function broadcastMessage(bytes32 messageId, bytes32 message, bytes32 signcryptionId) external isRSU {
        boardcastMessages[messageId].messageId = messageId;
        boardcastMessages[messageId].rsuId = msg.sender;
        boardcastMessages[messageId].signcryptionId = signcryptionId;
        boardcastMessages[messageId].message = message;
        boardcastMessages[messageId].availability = true;

        emit AddedBroadcastMessage(messageId, signcryptionId, msg.sender, message);
    }

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

    function isTrustedVehi(address vehiId) external view returns (bool, int256) {
        return (trustedVehicles[vehiId].state, trustedVehicles[vehiId].reputationvalue);
    }

    function storageSigncryptionReward(bytes32 signcryptionId, int256 rewardvalue) external isTD {
        signcryptions[signcryptionId].rewardvalue = rewardvalue;

        emit StorageSigncryptionReward(signcryptionId, rewardvalue);
    }

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

    // Todo 1: 车辆A发布任务，预先提交一部分信用值，车辆B接收任务，完成任务以后领取奖励
    // Q: 如何做到匿名的情况下扣除和领取信用值？
    // R：不需要做到匿名交易

    // Todo 2: TA 存储签密信息和路况信息到IPFS
    // V

    // *****考虑跨链问题，联盟链好做跨链*****
}