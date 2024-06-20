// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";

import "./library/LibStrings.sol";
import "./library/Base64.sol";
import "./interfaces/IFileInfos.sol";
import "./interfaces/IStorageBackend.sol";
import "./OCWebsiteFactory.sol";
import "./OCWebsite/OCWebsite.sol";

contract OCWebsiteFactoryToken {
    OCWebsiteFactory public websiteFactory;
    
    address fontData;

    constructor(bytes memory font) {
        fontData = SSTORE2.write(font);
    }

    // Due to difficulties with verifying source of contracts deployed by contracts, and 
    // this contract and DwebsiteFactory pointing to each other, we add the pointer to the blog factory
    // in this method, after this contract has been created.
    // Security : This can be only called once. Both pointers are set on websiteFactory constructor, 
    // so this method can be open
    function setWebsiteFactory(OCWebsiteFactory _websiteFactory) public {
        // We can only set the blog factory once
        require(address(websiteFactory) == address(0), "Already set");
        websiteFactory = _websiteFactory;
    }

    function tokenWeb3Address(uint tokenId) public view returns (string memory web3Address) {
        require(tokenId < websiteFactory.totalSupply(), "Token does not exist");

        OCWebsite website = websiteFactory.websites(tokenId);

        // uint subdomainLength = bytes(website.subdomain()).length;
        // if(subdomainLength > 0) {
        //     web3Address = string.concat("web3://", website.subdomain(), ".", websiteFactory.domain(), ".", websiteFactory.topdomain());
        // }
        // else {
            web3Address = string.concat(
                "web3://", 
                LibStrings.toHexString(address(website)));

            uint chainId = block.chainid;
            IStorageBackend storageBackend = website.getLiveFrontendVersion().storageBackend;
            // TODO: Override based on storageBackend
            // if(LibStrings.compare(storageBackend.name(), "EthStorage")) {
            //     // if(block.chainid == 1) {
            //     //     chainId = 333;
            //     // }
            //     // else if(block.chainid == 11155111) {
            //     //     chainId = 3333;
            //     // }
            // }
            if(chainId > 1) {
                web3Address = string.concat(web3Address, ":", LibStrings.toString(chainId));
            }
        // }
    }

    function tokenSVG(uint tokenId) public view returns (string memory) {
        require(tokenId < websiteFactory.totalSupply(), "Token does not exist");

        OCWebsite website = websiteFactory.websites(tokenId);

        // Prepare the colors
        string memory color = "#e0a43a";
        string memory colorShadow = "#b0802e";

        // Prepare the address part
        string memory svgAddressPart = "";
        string memory addressStr = tokenWeb3Address(tokenId);
        addressStr = LibStrings.substring(addressStr, 7, bytes(addressStr).length);
        string memory addressStrPart1 = LibStrings.substring(addressStr, 0, 24);
        string memory addressStrPart2 = LibStrings.substring(addressStr, 24, bytes(addressStr).length);

        svgAddressPart = string.concat(
            '<text x="20" y="90" font-size="15">'
                '<tspan x="20" dy="-1.2em">', addressStrPart1, '</tspan>'
                '<tspan x="20" dy="1.2em">', addressStrPart2, '</tspan>'
            '</text>'
        );

        return string.concat(
            '<svg width="256" height="256" viewBox="0 0 256 256" fill="none" xmlns="http://www.w3.org/2000/svg">'
                '<style>'
                    '@font-face{'
                        'font-family: "IBMPlexMono";src:url(data:font/woff2;base64,',
                        Base64.encode(SSTORE2.read(fontData)),
                        ') format("woff2");'
                        'font-weight: normal;'
                        'font-style: normal;'
                    '}'
                    'text {'
                        'font-family: IBMPlexMono;'
                        'font-weight: bold;'
                        'font-style: normal;'
                        'fill : white;'
                        'filter: drop-shadow(0px 0px 3px ', colorShadow, ');'
                    '}'
                '</style>'
                '<rect width="256" height="256" fill="', color, '" />'
                '<text x="20" y="45" font-size="30">'
                    'web3://'
                '</text>',
                // Samples:
                // '<text x="20" y="90" font-size="15">'
                //     '<tspan x="20" dy="-1.2em">0x1613beB3B2C4f22Ee086B2</tspan>'
                //     '<tspan x="20" dy="1.2em">b38C1476A3cE7f78E8:333</tspan>'
                // '</text>'
                svgAddressPart,
                '<text x="70" y="230" font-size="30">'
                    'OCWebsite'
                '</text>'
            '</svg>'
        );
    }

    function tokenURI(uint tokenId) public view returns (string memory) {
        require(tokenId < websiteFactory.totalSupply(), "Token does not exist");

        OCWebsite website = websiteFactory.websites(tokenId);

        string memory svg = tokenSVG(tokenId);
        string memory web3Address = tokenWeb3Address(tokenId);

        return string.concat(
            '{'
                '"id": "', LibStrings.toString(tokenId), '", '
                '"name": "', web3Address, '", '
                '"description": "A on-chain website using the web3:// protocol", '
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),'", '
                '"external_url": "', web3Address, '"'
            '}'
        );
    }
}