// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "./Ownable.sol";

contract SettingsLockable is Ownable {
    bool public settingsLocked = false;

    error SettingsLocked();

    modifier settingsUnlocked() {
        if(settingsLocked == true) {
            revert SettingsLocked();
        }
        _;
    }

    function lockSettings() public onlyOwner settingsUnlocked {
        settingsLocked = true;
    }
}