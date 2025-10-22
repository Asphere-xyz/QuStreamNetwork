// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title QuStreamRequestManager
/// @notice Manages encryption requests, withdrawal addresses and fee logic for the QuStream protocol.
/// @dev Owner can manage withdrawal addresses and fee settings. Master node processes requests and updates their status.
contract QuStreamRequestManager is Ownable, ReentrancyGuard {
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
    /// @param status Current status of the request
    /// @param paidFee Exact fee paid at registration
    struct Request {
        uint256 id;
        address sender;
        Status status;
        uint256 paidFee;
    }

    /// @notice Address that receives QuStream fees
    address public _qustreamFeeOwner;
    /// @notice Address that receives encryption node fees
    address public _encryptionNodeFeeOwner;
    /// @notice Address that is allowed to process requests
    address public _masterNode;
    /// @notice Mapping of request ID to Request struct
    mapping(uint256 => Request) public _requests;
    /// @notice Next request ID to be assigned
    uint256 public _nextRequestId = 1;
    /// @notice Fee required to register a request
    uint256 public _userFee;
    /// @notice Fee percentage taken by QuStream from each request (0..100)
    uint256 public _qustreamFeePercentage = 40; // 40%

    /// @notice Emitted when a new request is registered
    /// @param id The request ID
    /// @param sender The address that registered the request
    /// @param paidFee The fee paid for the request
    event RequestRegistered(uint256 indexed id, address indexed sender, uint256 paidFee);
    /// @notice Emitted when a request's status is updated
    /// @param id The request ID
    /// @param status The new status
    event RequestStatusUpdated(uint256 indexed id, Status status);
    /// @notice Emitted when the QuStream fee owner is updated
    /// @param newOwner The new fee owner address
    event QuStreamFeeOwnerUpdated(address newOwner);
    /// @notice Emitted when the encryption node fee owner is updated
    /// @param newOwner The new fee owner address
    event EncryptionNodeFeeOwnerUpdated(address newOwner);
    /// @notice Emitted when the master node address is updated
    /// @param newMasterNode The new master node address
    event MasterNodeUpdated(address newMasterNode);
    /// @notice Emitted when the user fee is updated
    /// @param newUserFee The new user fee value
    event UserFeeUpdated(uint256 newUserFee);
    /// @notice Emitted when the QuStream fee percentage is updated
    /// @param newQuStreamFeePercentage The new fee percentage value
    event QuStreamFeePercentageUpdated(uint256 newQuStreamFeePercentage);
    /// @notice Emitted when fees are distributed for a processed request (transferred immediately)
    /// @param id The request ID
    /// @param qustreamFee The amount sent to the QuStream fee owner
    /// @param nodeFee The amount sent to the encryption node fee owner
    /// @param qustreamOwner The QuStream fee owner address
    /// @param nodeOwner The encryption node fee owner address
    event FeeDistributed(
        uint256 indexed id, uint256 qustreamFee, uint256 nodeFee, address qustreamOwner, address nodeOwner
    );

    /// @notice Initializes the contract with ownership and fee settings
    /// @param contractOwner The address to be set as contract owner
    /// @param qustreamFeeOwner The address that receives QuStream fees
    /// @param encryptionNodeFeeOwner The address that receives encryption node fees
    /// @param masterNode The address allowed to process requests
    /// @param userFee The user fee required to register a request
    /// @param qustreamFeePercentage The percentage of the fee taken by QuStream
    constructor(
        address contractOwner,
        address qustreamFeeOwner,
        address encryptionNodeFeeOwner,
        address masterNode,
        uint256 userFee,
        uint256 qustreamFeePercentage
    ) Ownable(contractOwner) {
        require(qustreamFeeOwner != address(0), "qustream fee owner zero");
        require(encryptionNodeFeeOwner != address(0), "encryption node fee owner zero");
        require(masterNode != address(0), "master node zero");
        require(qustreamFeePercentage <= 100, "percentage>100");

        _qustreamFeeOwner = qustreamFeeOwner;
        _encryptionNodeFeeOwner = encryptionNodeFeeOwner;
        _masterNode = masterNode;
        _userFee = userFee;
        _qustreamFeePercentage = qustreamFeePercentage;
    }

    /// @notice Prevent accidental direct sends; require registerRequest for payments
    receive() external payable {
        revert("direct sends not accepted; use registerRequest()");
    }

    /// @notice Sets the address that receives collected QuStream portion of the fees
    /// @dev Only callable by the contract owner
    /// @param newOwner The new fee owner address
    function setQuStreamFeeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        _qustreamFeeOwner = newOwner;
        emit QuStreamFeeOwnerUpdated(newOwner);
    }

    /// @notice Sets the encryption node fee owner address
    /// @dev Only callable by the contract owner
    /// @param newOwner The new encryption node fee owner address
    function setEncryptionNodeFeeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        _encryptionNodeFeeOwner = newOwner;
        emit EncryptionNodeFeeOwnerUpdated(newOwner);
    }

    /// @notice Sets the master node address
    /// @dev Only callable by the contract owner
    /// @param newMasterNode The new master node address
    function setMasterNode(address newMasterNode) external onlyOwner {
        require(newMasterNode != address(0), "zero address");
        _masterNode = newMasterNode;
        emit MasterNodeUpdated(newMasterNode);
    }

    /// @notice Sets the user fee required to register a request
    /// @dev Only callable by the contract owner
    /// @param newUserFee The new user fee value
    function setUserFee(uint256 newUserFee) external onlyOwner {
        _userFee = newUserFee;
        emit UserFeeUpdated(newUserFee);
    }

    /// @notice Sets the QuStream fee percentage
    /// @dev Only callable by the contract owner
    /// @param newQuStreamFeePercentage The new fee percentage value
    function setQuStreamFeePercentage(uint256 newQuStreamFeePercentage) external onlyOwner {
        require(newQuStreamFeePercentage <= 100, "percentage>100");
        _qustreamFeePercentage = newQuStreamFeePercentage;
        emit QuStreamFeePercentageUpdated(newQuStreamFeePercentage);
    }

    /// @notice Registers a new encryption request
    /// @dev Requires payment of the current fee. Emits RequestRegistered.
    /// @return id The ID of the newly created request
    function registerRequest() external payable returns (uint256 id) {
        require(msg.value == _userFee, "incorrect fee");
        id = _nextRequestId++;
        _requests[id] = Request({id: id, sender: msg.sender, status: Status.Pending, paidFee: msg.value});
        emit RequestRegistered(id, msg.sender, msg.value);
    }

    /// @notice Processes an encryption request and updates its status
    /// @dev Only callable by the configured master node. Emits RequestStatusUpdated. Deletes request on success, marks as failed otherwise. Sends fees immediately to fee owners. Uses nonReentrant modifier.
    /// @param id The ID of the request to process
    /// @param status The new status (Success or Fail)
    function processRequest(uint256 id, Status status) external nonReentrant {
        require(msg.sender == _masterNode, "not authorized");
        require(status == Status.Success || status == Status.Fail, "invalid status");
        Request storage req = _requests[id];
        require(req.id != 0, "request does not exist or is already processed");

        if (status == Status.Success) {
            uint256 paid = req.paidFee;

            delete _requests[id];
            emit RequestStatusUpdated(id, Status.Success);

            uint256 qustreamFee = (paid * _qustreamFeePercentage) / 100;
            uint256 encryptionNodeFee = paid - qustreamFee;

            payable(_qustreamFeeOwner).sendValue(qustreamFee);
            payable(_encryptionNodeFeeOwner).sendValue(encryptionNodeFee);

            emit FeeDistributed(id, qustreamFee, encryptionNodeFee, _qustreamFeeOwner, _encryptionNodeFeeOwner);
        } else if (status == Status.Fail) {
            // for failed requests we currently keep the fee and we allow master node to process the request again; design choice — could implement refund logic here.
            req.status = Status.Fail;
            emit RequestStatusUpdated(id, Status.Fail);
        }
    }
}
