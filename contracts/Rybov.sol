// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Rybov
 * @dev A token for use between spouses and friends for completing tasks
 * like "Make tea", "Clean the bathroom", etc.
 * Designed to be deployed on the Polygon network.
 */
contract Rybov is Initializable, ERC20Upgradeable, ERC20PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    // Task status enum
    enum TaskStatus { Created, Completed, Verified, Cancelled }

    // Task structure
    struct Task {
        string description;
        uint256 reward;
        address creator;
        address assignee;
        TaskStatus status;
        uint256 createdAt;
        uint256 completedAt;
    }

    // Relationship structure
    struct Relationship {
        bool exists;
        string relationshipType; // "spouse", "friend", etc.
    }

    // Task ID counter
    uint256 private _taskIdCounter;

    // Mapping from task ID to Task
    mapping(uint256 => Task) private _tasks;

    // Mapping from user to their tasks (as assignee)
    mapping(address => uint256[]) private _userTasks;

    // Mapping from user to their created tasks
    mapping(address => uint256[]) private _userCreatedTasks;

    // Mapping for relationships between users
    mapping(address => mapping(address => Relationship)) private _relationships;

    // Events
    event TaskCreated(uint256 indexed taskId, address indexed creator, address indexed assignee, string description, uint256 reward);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee);
    event TaskVerified(uint256 indexed taskId, address indexed verifier);
    event TaskCancelled(uint256 indexed taskId, address indexed canceller);
    event RelationshipEstablished(address indexed user1, address indexed user2, string relationshipType);
    event RelationshipRemoved(address indexed user1, address indexed user2);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC20_init("Rybov", "RBV");
        __ERC20Pausable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init("Rybov");
        __UUPSUpgradeable_init();

        // Initialize task counter
        _taskIdCounter = 0;
    }

    /**
     * @dev Creates a new task and assigns it to a user
     * @param assignee The address of the user to whom the task is assigned
     * @param description Description of the task
     * @param reward Amount of tokens to reward upon completion
     * @return taskId The ID of the created task
     */
    function createTask(address assignee, string memory description, uint256 reward) public returns (uint256) {
        require(assignee != address(0), "Assignee cannot be zero address");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(reward > 0, "Reward must be greater than zero");
        require(_relationships[msg.sender][assignee].exists, "No relationship exists with assignee");

        uint256 taskId = _taskIdCounter++;

        _tasks[taskId] = Task({
            description: description,
            reward: reward,
            creator: msg.sender,
            assignee: assignee,
            status: TaskStatus.Created,
            createdAt: block.timestamp,
            completedAt: 0
        });

        _userTasks[assignee].push(taskId);
        _userCreatedTasks[msg.sender].push(taskId);

        emit TaskCreated(taskId, msg.sender, assignee, description, reward);

        return taskId;
    }

    /**
     * @dev Marks a task as completed by the assignee
     * @param taskId The ID of the task to mark as completed
     */
    function completeTask(uint256 taskId) public {
        Task storage task = _tasks[taskId];

        require(task.creator != address(0), "Task does not exist");
        require(task.assignee == msg.sender, "Only assignee can complete the task");
        require(task.status == TaskStatus.Created, "Task is not in created state");

        task.status = TaskStatus.Completed;
        task.completedAt = block.timestamp;

        emit TaskCompleted(taskId, msg.sender);
    }

    /**
     * @dev Verifies a completed task and rewards the assignee
     * @param taskId The ID of the task to verify
     */
    function verifyTask(uint256 taskId) public {
        Task storage task = _tasks[taskId];

        require(task.creator != address(0), "Task does not exist");
        require(task.creator == msg.sender, "Only creator can verify the task");
        require(task.status == TaskStatus.Completed, "Task is not completed");

        task.status = TaskStatus.Verified;

        // Mint tokens as reward
        _mint(task.assignee, task.reward);

        emit TaskVerified(taskId, msg.sender);
    }

    /**
     * @dev Cancels a task
     * @param taskId The ID of the task to cancel
     */
    function cancelTask(uint256 taskId) public {
        Task storage task = _tasks[taskId];

        require(task.creator != address(0), "Task does not exist");
        require(task.creator == msg.sender || task.assignee == msg.sender, "Only creator or assignee can cancel");
        require(task.status == TaskStatus.Created, "Task can only be cancelled if in created state");

        task.status = TaskStatus.Cancelled;

        emit TaskCancelled(taskId, msg.sender);
    }

    /**
     * @dev Establishes a relationship between two users
     * @param user The address of the user to establish a relationship with
     * @param relationshipType The type of relationship ("spouse", "friend", etc.)
     */
    function establishRelationship(address user, string memory relationshipType) public {
        require(user != address(0), "User cannot be zero address");
        require(user != msg.sender, "Cannot establish relationship with yourself");
        require(bytes(relationshipType).length > 0, "Relationship type cannot be empty");

        _relationships[msg.sender][user] = Relationship({
            exists: true,
            relationshipType: relationshipType
        });

        _relationships[user][msg.sender] = Relationship({
            exists: true,
            relationshipType: relationshipType
        });

        emit RelationshipEstablished(msg.sender, user, relationshipType);
    }

    /**
     * @dev Removes a relationship between two users
     * @param user The address of the user to remove the relationship with
     */
    function removeRelationship(address user) public {
        require(_relationships[msg.sender][user].exists, "Relationship does not exist");

        delete _relationships[msg.sender][user];
        delete _relationships[user][msg.sender];

        emit RelationshipRemoved(msg.sender, user);
    }

    /**
     * @dev Gets a task by ID
     * @param taskId The ID of the task to get
     */
    function getTask(uint256 taskId) public view returns (
        string memory description,
        uint256 reward,
        address creator,
        address assignee,
        TaskStatus status,
        uint256 createdAt,
        uint256 completedAt
    ) {
        Task storage task = _tasks[taskId];
        require(task.creator != address(0), "Task does not exist");

        return (
            task.description,
            task.reward,
            task.creator,
            task.assignee,
            task.status,
            task.createdAt,
            task.completedAt
        );
    }

    /**
     * @dev Gets all tasks assigned to a user
     * @param user The address of the user
     * @return Array of task IDs assigned to the user
     */
    function getUserTasks(address user) public view returns (uint256[] memory) {
        return _userTasks[user];
    }

    /**
     * @dev Gets all tasks created by a user
     * @param user The address of the user
     * @return Array of task IDs created by the user
     */
    function getUserCreatedTasks(address user) public view returns (uint256[] memory) {
        return _userCreatedTasks[user];
    }

    /**
     * @dev Checks if a relationship exists between two users
     * @param user1 First user address
     * @param user2 Second user address
     * @return exists Whether the relationship exists
     * @return relationshipType The type of relationship
     */
    function getRelationship(address user1, address user2) public view returns (bool exists, string memory relationshipType) {
        Relationship storage relationship = _relationships[user1][user2];
        return (relationship.exists, relationship.relationshipType);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._update(from, to, value);
    }
}
