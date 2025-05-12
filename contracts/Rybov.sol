// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

/**
 * @title Rybov
 * @dev A simple ERC20 token designed to be deployed on the Polygon network.
 *
 * This contract uses the UUPS (Universal Upgradeable Proxy Standard) pattern
 * for upgradeability. The upgradeTo and upgradeToAndCall functions are inherited
 * from UUPSUpgradeable and are restricted to the owner through the _authorizeUpgrade
 * function which has the onlyOwner modifier.
 *
 * Security considerations:
 * - Only the owner can upgrade the contract, pause/unpause token transfers, and mint new tokens
 */
contract Rybov is Initializable, ERC20Upgradeable, ERC20PausableUpgradeable, Ownable2StepUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {

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
