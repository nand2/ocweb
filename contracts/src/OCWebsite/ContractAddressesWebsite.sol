// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { LibStrings } from "../library/LibStrings.sol";
import { SettingsLockable } from "../library/SettingsLockable.sol";

import "./ResourceRequestWebsite.sol";

/**
 * Extension: Expose a list of contract addresses at the /contractAddresses.json endpoint
 * This is useful for the frontend to know where to find the contracts and to start building
 * web3:// addresses to call them
 */
contract ContractAddressesWebsite is ResourceRequestWebsite, SettingsLockable {
    struct NamedAddressAndChainId {
        string name;
        address addr;
        uint chainId;
    }
    NamedAddressAndChainId[] public staticContractAddresses;

    constructor() {}

    function addStaticContractAddress(string memory name, address addr, uint chainId) public onlyOwner settingsUnlocked {
        // Reserved names
        require(LibStrings.compare(name, "self") == false, "Name reserved");
        // Ensure the name was not used yet
        for(uint i = 0; i < staticContractAddresses.length; i++) {
            require(LibStrings.compare(staticContractAddresses[i].name, name) == false, "Name already used");
        }

        staticContractAddresses.push(NamedAddressAndChainId(name, addr, chainId));
    }

    function getStaticContractAddresses() public view returns (NamedAddressAndChainId[] memory) {
        return staticContractAddresses;
    }

    function removeStaticContractAddress(uint index) public onlyOwner settingsUnlocked {
        require(index < staticContractAddresses.length, "Index out of bounds");

        staticContractAddresses[index] = staticContractAddresses[staticContractAddresses.length - 1];
        staticContractAddresses.pop();
    }

    /**
     * Hook to override
     * If you want to add some dynamically added contract addresses, override this function
     */
    function _getContractAddresses() internal virtual view returns (NamedAddressAndChainId[] memory) {
        return staticContractAddresses;
    }

    /**
     * Return an answer to a web3:// request after the static frontend is served
     * @return statusCode The HTTP status code to return. Returns 0 if you do not wish to
     *                   process the call
     */
    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual override view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        if(resource.length == 1 && LibStrings.compare(resource[0], "contractAddresses.json")) {
            // We output all the static contract addresses and ourselves
            // Manual JSON serialization, safe with the vars we encode
            body = string.concat('{'
                '"self":{'
                    '"address":"', LibStrings.toHexString(address(this)), '",'
                    '"chainId":', LibStrings.toString(block.chainid), 
                '}');

            NamedAddressAndChainId[] memory contractAddresses = _getContractAddresses();
            for(uint i = 0; i < contractAddresses.length; i++) {
                body = string.concat(body, ','
                '"', contractAddresses[i].name, '":{'
                    '"address":"', LibStrings.toHexString(contractAddresses[i].addr), '",',
                    '"chainId":', LibStrings.toString(contractAddresses[i].chainId), 
                '}');
            }
            body = string.concat(body, '}');
            
            statusCode = 200;
            headers = new KeyValue[](1);
            headers[0].key = "Content-type";
            headers[0].value = "application/json";
            return (statusCode, body, headers);
        }

        (statusCode, body, headers) = super._processWeb3Request(resource, params);
    }
        
}
