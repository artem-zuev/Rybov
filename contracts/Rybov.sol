// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Rybov
 * @dev A token for use between spouses and friends for completing tasks
 * like "Make tea", "Clean the bathroom", etc.
 * Designed to be deployed on the Polygon network.
 *
 * This contract uses the UUPS (Universal Upgradeable Proxy Standard) pattern
 * for upgradeability. The upgradeTo and upgradeToAndCall functions are inherited
 * from UUPSUpgradeable and are restricted to the owner through the _authorizeUpgrade
 * function which has the onlyOwner modifier.
 *
 * Security considerations:
 * - Only the owner can upgrade the contract, pause/unpause token transfers, and mint new tokens
 * - Task creation, completion, verification, and cancellation have specific access controls
 * - Relationships must be established before tasks can be created between users
 */
contract Rybov is Initializable, ERC20Upgradeable, ERC20PausableUpgradeable, Ownable2StepUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    // Task status enum
    enum TaskStatus { Created, Completed, Verified, Cancelled }

    // Task structure - fields ordered for optimal packing
    struct Task {
        // Group addresses together
        address creator;
        address assignee;
        // Group uint256 values together
        uint256 reward;
        uint256 createdAt;
        uint256 completedAt;
        // Enum and string
        TaskStatus status;
        string description;
    }

    // Relationship structure
    struct Relationship {
        bool exists;
        string relationshipType; // "spouse", "friend", etc.
    }

    // Task ID counter
    uint256 private _taskIdCounter;

    // Mapping from task ID to Task
    mapping(uint256 taskId => Task task) private _tasks;

    // Mapping from user to their tasks (as assignee)
    mapping(address user => uint256[] taskIds) private _userTasks;

    // Mapping from user to their created tasks
    mapping(address creator => uint256[] taskIds) private _userCreatedTasks;

    // Mapping for relationships between users
    mapping(address user1 => mapping(address user2 => Relationship relationship)) private _relationships;

    // Events
    event TaskCreated(uint256 indexed taskId, address indexed creator, address indexed assignee, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee);
    event TaskVerified(uint256 indexed taskId, address indexed verifier);
    event TaskCancelled(uint256 indexed taskId, address indexed canceller);
    event RelationshipEstablished(address indexed user1, address indexed user2, string relationshipType);
    event RelationshipRemoved(address indexed user1, address indexed user2);

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @dev Constructor is marked as payable to save gas
    constructor() payable {
        _disableInitializers();
    }

    /// @dev Initializes the contract with the initial owner and sets up the token
    /// @param initialOwner The address that will be the initial owner of the contract
    function initialize(address initialOwner) initializer public {
        require(initialOwner != address(0), "Owner cannot be zero address");
        __ERC20_init("Rybov", "RBV");
        __ERC20Pausable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init("Rybov");
        __UUPSUpgradeable_init();

        // Initialize task counter to 1 to avoid zero-to-one storage write
        _taskIdCounter = 1;
    }

    /**
     * @dev Creates a new task and assigns it to a user
     * @param assignee The address of the user to whom the task is assigned
     * @param description Description of the task
     * @param reward Amount of tokens to reward upon completion
     * @return taskId The ID of the created task
     */
    /// @dev Creates a new task and assigns it to a user
    /// @param assignee The address of the user to whom the task is assigned
    /// @param description Description of the task
    /// @param reward Amount of tokens to reward upon completion
    /// @return taskId The ID of the created task
    function createTask(address assignee, string memory description, uint256 reward) public returns (uint256 taskId) {
        require(assignee != address(0), "Assignee cannot be 0");
        require(bytes(description).length != 0, "Description empty");
        require(reward != 0, "Reward must be > 0");
        require(_relationships[msg.sender][assignee].exists, "No relationship");

        taskId = _taskIdCounter++;

        // More gas efficient to initialize empty and assign individually
        Task storage task = _tasks[taskId];
        task.creator = msg.sender;
        task.assignee = assignee;
        task.reward = reward;
        task.createdAt = block.timestamp;
        delete task.completedAt; // More gas efficient than setting to 0
        task.status = TaskStatus.Created;
        task.description = description;

        _userTasks[assignee].push(taskId);
        _userCreatedTasks[msg.sender].push(taskId);

        emit TaskCreated(taskId, msg.sender, assignee, description, reward);
    }

    /// @dev Marks a task as completed by the assignee
    /// @param taskId The ID of the task to mark as completed
    /// @notice Uses block.timestamp which is not precise and can be manipulated slightly by miners
    function completeTask(uint256 taskId) public {
        Task storage task = _tasks[taskId];

        require(task.creator != address(0), "Task not found");
        require(task.assignee == msg.sender, "Only assignee");
        require(task.status == TaskStatus.Created, "Not in created state");

        task.status = TaskStatus.Completed;
        // Using block.timestamp as completion time - note this is not completely precise
        task.completedAt = block.timestamp;

        emit TaskCompleted(taskId, msg.sender);
    }

    /// @dev Verifies a completed task and rewards the assignee
    /// @param taskId The ID of the task to verify
    /// @notice Only the task creator can verify a task
    function verifyTask(uint256 taskId) public {
        Task storage task = _tasks[taskId];

        require(task.creator != address(0), "Task not found");
        require(task.creator == msg.sender, "Only creator");
        require(task.status == TaskStatus.Completed, "Not completed");

        task.status = TaskStatus.Verified;

        // Mint tokens as reward
        _mint(task.assignee, task.reward);

        emit TaskVerified(taskId, msg.sender);
    }

    /// @dev Cancels a task
    /// @param taskId The ID of the task to cancel
    /// @notice Only the task creator or assignee can cancel a task
    function cancelTask(uint256 taskId) public {
        Task storage task = _tasks[taskId];

        require(task.creator != address(0), "Task not found");
        require(task.creator == msg.sender || task.assignee == msg.sender, "Not authorized");
        require(task.status == TaskStatus.Created, "Not in created state");

        task.status = TaskStatus.Cancelled;

        emit TaskCancelled(taskId, msg.sender);
    }

    /// @dev Establishes a relationship between two users
    /// @param user The address of the user to establish a relationship with
    /// @param relationshipType The type of relationship ("spouse", "friend", etc.)
    function establishRelationship(address user, string memory relationshipType) public {
        require(user != address(0), "User cannot be 0");
        require(user != msg.sender, "Cannot relate to self");
        require(bytes(relationshipType).length != 0, "Type empty");

        // More gas efficient to initialize empty and assign individually
        Relationship storage relationship1 = _relationships[msg.sender][user];
        relationship1.exists = true;
        relationship1.relationshipType = relationshipType;

        Relationship storage relationship2 = _relationships[user][msg.sender];
        relationship2.exists = true;
        relationship2.relationshipType = relationshipType;

        emit RelationshipEstablished(msg.sender, user, relationshipType);
    }

    /// @dev Removes a relationship between two users
    /// @param user The address of the user to remove the relationship with
    function removeRelationship(address user) public {
        // Cache storage variable in memory for gas efficiency
        bool relationshipExists = _relationships[msg.sender][user].exists;
        require(relationshipExists, "No relationship");

        delete _relationships[msg.sender][user];
        delete _relationships[user][msg.sender];

        emit RelationshipRemoved(msg.sender, user);
    }

    /// @dev Gets a task by ID
    /// @param taskId The ID of the task to get
    /// @return Task struct containing all task details
    function getTask(uint256 taskId) public view returns (Task memory) {
        Task storage task = _tasks[taskId];
        require(task.creator != address(0), "Task not found");

        return task;
    }

    /// @dev Gets all tasks assigned to a user
    /// @param user The address of the user
    /// @return Array of task IDs assigned to the user
    function getUserTasks(address user) public view returns (uint256[] memory) {
        return _userTasks[user];
    }

    /// @dev Gets all tasks created by a user
    /// @param user The address of the user
    /// @return Array of task IDs created by the user
    function getUserCreatedTasks(address user) public view returns (uint256[] memory) {
        return _userCreatedTasks[user];
    }

    /// @dev Checks if a relationship exists between two users
    /// @param user1 First user address
    /// @param user2 Second user address
    /// @return exists Whether the relationship exists
    /// @return relationshipType The type of relationship
    function getRelationship(address user1, address user2) public view returns (bool exists, string memory relationshipType) {
        // Cache storage variable in memory for gas efficiency
        Relationship storage relationship = _relationships[user1][user2];
        return (relationship.exists, relationship.relationshipType);
    }

    /// @dev Pauses all token transfers
    /// @notice Only the owner can pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpauses all token transfers
    /// @notice Only the owner can unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev Mints new tokens and assigns them to the specified address
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens to mint
    /// @notice Only the owner can mint new tokens
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to 0 address");
        _mint(to, amount);
    }

    /// @dev Required by the UUPSUpgradeable contract to restrict upgrade access
    /// @param newImplementation Address of the new implementation
    /// @notice This function is required by the UUPS pattern and is called during upgrades
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {
        // Additional upgrade logic can be added here if needed
        // The onlyOwner modifier ensures only the owner can upgrade the contract
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._update(from, to, value);
    }
}
