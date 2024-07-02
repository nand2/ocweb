// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OCWebsite.sol";

contract ClonableOCWebsite is OCWebsite {
    error AlreadyInitialized();

    constructor() OCWebsite() {
    }

    // An optional controller for the ownership. 
    // E.g. if this OCWebsite is created as an ERC721 token, the ownership 
    // controller will be the ERC721 contract
    // If the ownership controller is set, the ownership controller only can transfer the ownership
    // If the ownership controller is not set, the owner only can transfer the ownership
    address public ownershipController;

    modifier onlyOwnershipControllerOrOwnerIfNotSet() {
        if((ownershipController != address(0) && msg.sender != ownershipController) || 
            (ownershipController == address(0) && msg.sender != owner)) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * Initialize the OCWebsite after a cloning.
     * @param _owner The owner of the website
     * @param _ownershipController The controller of the ownership. Can be null.
     */
    function initialize(address _owner, address _ownershipController, IStorageBackend firstFrontendVersionStorageBackend) public {
        if(owner != address(0)) {
            revert AlreadyInitialized();
        }
        if(_owner == address(0)) {
            revert InvalidNewOwner();
        }
        owner = _owner;
        ownershipController = _ownershipController;

        // Add the first frontend version
        if(address(firstFrontendVersionStorageBackend) != address(0)) {
            _addFrontendVersion(firstFrontendVersionStorageBackend, "Initial version");
        }
    }

    /**
     * Transfer the ownership of the website. If there is a controller for the ownership,
     * only the controller can transfer the ownership. If there is no controller, the owner only
     * can transfer the ownership.
     * @param _newOwner The new owner of the website
     */
    function transferOwnership(address _newOwner) public override onlyOwnershipControllerOrOwnerIfNotSet {
        if(_newOwner == address(0)) {
            revert InvalidNewOwner();
        }
        owner = _newOwner;
    }
}
