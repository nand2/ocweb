// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "./Ownable.sol";

contract SettingsLockable is Ownable {
    bool public settingsLocked = false;

    modifier settingsUnlocked() {
        require(settingsLocked == false, "Settings locked");
        _;
    }

    function lockSettings() public onlyOwner {
        require(settingsLocked == false, "Settings locked");
        settingsLocked = true;
    }
}