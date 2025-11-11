// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title QuStreamRequestManager
/// @notice Manages encryption requests for the QuStream protocol.
/// @dev Master node processes requests and updates their status.
contract QuStreamRequestManager is Ownable {
    using Address for address payable;

    /// @notice Status of an encryption request
    enum Status {
        Pending,
        Success,
        Fail
    }

    /// @notice Struct representing an encryption request
    /// @param id Unique request ID
    /// @param sender Address that created the request
    struct Request {
        uint256 id;
        address sender;
        string userID;
        string qBlock;
    }

    /// @notice Address that is allowed to process requests
    address public _masterNode;
    /// @notice Mapping of request ID to Request struct
    mapping(uint256 => Request) public _requests;
    /// @notice Next request ID to be assigned
    uint256 public _nextRequestId = 1;

    /// @notice Emitted when a new request is registered
    /// @param id The request ID
    /// @param sender The address that registered the request
    /// @param userID The user ID
    /// @param qBlock The qBlock
    event RequestRegistered(uint256 indexed id, address indexed sender, string userID, string qBlock);
    /// @notice Emitted when a request's status is updated
    /// @param id The request ID
    /// @param status The new status
    event RequestStatusUpdated(uint256 indexed id, Status status);
    /// @notice Emitted when the QuStream master node is updated
    /// @param newMasterNode The new master node address
    event MasterNodeUpdated(address newMasterNode);

    /// @notice Initializes the contract with ownership
    /// @param contractOwner The address to be set as contract owner. Only this address can update master node
    /// @param masterNode The address allowed to process requests
    constructor(address contractOwner, address masterNode) Ownable(contractOwner) {
        require(masterNode != address(0), "master node zero");
        _masterNode = masterNode;
    }

    /// @notice Prevent accidental direct sends; require registerRequest for payments
    receive() external payable {
        revert("direct sends not accepted; use registerRequest()");
    }

    /// @notice Sets the master node address
    /// @dev Only callable by the contract owner
    /// @param newMasterNode The new master node address
    function setMasterNode(address newMasterNode) external onlyOwner {
        require(newMasterNode != address(0), "zero address");
        _masterNode = newMasterNode;
        emit MasterNodeUpdated(newMasterNode);
    }

    /// @notice Registers a new encryption request
    /// @dev Emits RequestRegistered.
    /// @param userID Optional user ID string
    /// @param qBlock Optional qBlock string
    /// @return id The ID of the newly created request
    function registerRequest(string calldata userID, string calldata qBlock) external payable returns (uint256 id) {
        id = _nextRequestId++;
        _requests[id] = Request({id: id, sender: msg.sender, userID: userID, qBlock: qBlock});
        emit RequestRegistered(id, msg.sender, userID, qBlock);
    }

    /// @notice Processes an encryption request and updates its status
    /// @dev Only callable by the configured master node. Emits RequestStatusUpdated
    /// @param id The ID of the request to process
    /// @param status The new status (Success or Fail)
    function processRequest(uint256 id, Status status) external {
        require(msg.sender == _masterNode, "not authorized");
        require(status == Status.Success || status == Status.Fail, "invalid status");
        Request storage req = _requests[id];
        require(req.id != 0, "request does not exist or is already processed");

        delete _requests[id];
        emit RequestStatusUpdated(id, status);
    }
}
