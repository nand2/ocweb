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

    function tokenSVGByVars(string memory subdomain, string memory addressStrPart1, string memory addressStrPart2) public view returns (string memory) {
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
                        'filter: drop-shadow(0px 0px 3px #b0802e);'
                    '}'
                '</style>'
                '<rect width="256" height="256" fill="#e0a43a" />'
                '<text x="128" y="45" font-size="30" text-anchor="middle">'
                    'OCWebsite'
                '</text>'
                '<text x="128" y="116" font-size="25" text-anchor="middle" dominant-baseline="middle">',
                    subdomain,
                '</text>'
                '<text x="20" y="195" font-size="20">'
                    'web3://'
                '</text>'
                '<text x="20" y="235" font-size="15">'
                    '<tspan x="20" dy="-1.2em">', addressStrPart1, '</tspan>'
                    '<tspan x="20" dy="1.2em">', addressStrPart2, '</tspan>'
                '</text>'
            '</svg>'
        );
    }

    function tokenSVG(uint tokenId) public view returns (string memory) {
        require(tokenId < websiteFactory.totalSupply(), "Token does not exist");

        OCWebsite website = websiteFactory.websites(tokenId);
        string memory subdomain = websiteFactory.websiteToSubdomain(website);

        // Prepare the address part
        string memory addressStr = websiteFactory.tokenWeb3Address(tokenId);
        addressStr = LibStrings.substring(addressStr, 7, bytes(addressStr).length);
        string memory addressStrPart1 = LibStrings.substring(addressStr, 0, 24);
        string memory addressStrPart2 = LibStrings.substring(addressStr, 24, bytes(addressStr).length);

        return tokenSVGByVars(subdomain, addressStrPart1, addressStrPart2);
    }

    function tokenURI(uint tokenId) public view returns (string memory) {
        require(tokenId < websiteFactory.totalSupply(), "Token does not exist");

        OCWebsite website = websiteFactory.websites(tokenId);

        string memory svg = tokenSVG(tokenId);
        string memory web3Address = websiteFactory.tokenWeb3Address(tokenId);

        return string.concat(
            '{'
                '"id": "', LibStrings.toString(tokenId), '", '
                '"name": "', websiteFactory.websiteToSubdomain(website), '", '
                '"description": "A onchain website using the web3:// protocol\\n\\nAddress: ', web3Address, '", '
                '"type": "website", ' // Non standard
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),'", '
                '"external_url": "', web3Address, '", '
                '"attributes": ['
                    // '{ "trait_type": "OCWebsite version", "value": ', LibStrings.toString(website.OCWebsiteVersion()), ' }'
                ']'
            '}'
        );
    }
}