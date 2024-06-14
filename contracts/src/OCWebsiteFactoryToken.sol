// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "./library/Strings.sol";
import "./library/Base64.sol";
import "./interfaces/IFileInfos.sol";
import "./interfaces/IStorageBackend.sol";
import "./OCWebsiteFactory.sol";

contract OCWebsiteFactoryToken {
    OCWebsiteFactory public websiteFactory;

    constructor() {}

    // Due to difficulties with verifying source of contracts deployed by contracts, and 
    // this contract and DwebsiteFactory pointing to each other, we add the pointer to the blog factory
    // in this method, after this contract has been created.
    // Security : This can be only called once. Both pointers are set on DwebsiteFactory constructor, 
    // so this method can be open
    function setwebsiteFactory(DwebsiteFactory _websiteFactory) public {
        // We can only set the blog factory once
        require(address(websiteFactory) == address(0), "Already set");
        websiteFactory = _websiteFactory;
    }

    function tokenWeb3Address(uint tokenId) public view returns (string memory web3Address) {
        require(tokenId < websiteFactory.getBlogCount(), "Token does not exist");

        DBlog blog = websiteFactory.blogs(tokenId);

        uint subdomainLength = bytes(blog.subdomain()).length;
        if(subdomainLength > 0) {
            web3Address = string.concat("web3://", blog.subdomain(), ".", websiteFactory.domain(), ".", websiteFactory.topdomain());
        }
        else {
            web3Address = string.concat(
                "web3://", 
                Strings.toHexString(address(blog.frontend())));

            uint chainId = block.chainid;
            IStorageBackend storageBackend = websiteFactory.storageBackends(blog.frontend().blogFrontendVersion().storageBackendIndex);
            if(Strings.compare(storageBackend.backendName(), "EthStorage")) {
                if(block.chainid == 1) {
                    chainId = 333;
                }
                else if(block.chainid == 11155111) {
                    chainId = 3333;
                }
            }
            if(chainId > 1) {
                web3Address = string.concat(web3Address, ":", Strings.toString(chainId));
            }
        }
    }

    function tokenSVG(uint tokenId) public view returns (string memory) {
        require(tokenId < websiteFactory.getBlogCount(), "Token does not exist");

        DBlog blog = websiteFactory.blogs(tokenId);

        // Prepare the brand initial: Uppercase the first 2 letters
        bytes memory brandInitialsBytes = new bytes(2);
        brandInitialsBytes[0] = bytes1(uint8(bytes(websiteFactory.domain())[0]) - 32);
        brandInitialsBytes[1] = bytes1(uint8(bytes(websiteFactory.domain())[1]) - 32);
        string memory brandInitials = string(brandInitialsBytes);

        // Prepare the colors
        string memory color = "#61c23e";
        string memory colorShadow = "#48912d";
        if(Strings.compare(websiteFactory.domain(), "bblog")) {
            color = "#0052ff";
            colorShadow = "#003ec2";
        }

        // Prepare the address part
        string memory svgAddressPart = "";
        uint subdomainLength = bytes(blog.subdomain()).length;
        if(subdomainLength > 0) {
            uint subdomainFontSize = 25;
            if(subdomainLength >= 15) {
                subdomainFontSize = 23 - (subdomainLength - 15);
            }

            svgAddressPart = string.concat(
                '<text x="20" y="53" font-size="25">',
                    '<tspan x="20" dy="1em" font-size="', Strings.toString(subdomainFontSize), '">', blog.subdomain(), '.</tspan>',
                    '<tspan x="20" dy="1.2em" opacity="0.6">', websiteFactory.domain(), '.', websiteFactory.topdomain(), '</tspan>',
                '</text>'
            );
        }
        else {
            string memory addressStr = tokenWeb3Address(tokenId);
            addressStr = Strings.substring(addressStr, 7, bytes(addressStr).length);
            string memory addressStrPart1 = Strings.substring(addressStr, 0, 24);
            string memory addressStrPart2 = Strings.substring(addressStr, 24, bytes(addressStr).length);

            svgAddressPart = string.concat(
                '<text x="20" y="90" font-size="15">'
                    '<tspan x="20" dy="-1.2em">', addressStrPart1, '</tspan>'
                    '<tspan x="20" dy="1.2em">', addressStrPart2, '</tspan>'
                '</text>'
            );
        }

        return string.concat(
            '<svg width="256" height="256" viewBox="0 0 256 256" fill="none" xmlns="http://www.w3.org/2000/svg">'
                '<style>'
                    '@font-face{'
                        'font-family: "IBMPlexMono";src:url(data:font/woff2;base64,',
                        websiteFactory.ethFsFileStore().readFile("IBMPlexMono-Regular.woff2"),
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
                // '<text x="20" y="53" font-size="25">'
                //     '<tspan x="20" dy="1em">nand.</tspan>'
                //     '<tspan x="20" dy="1.2em" opacity="0.6">dblog.eth</tspan>'
                // '</text>'
                svgAddressPart,
                '<text x="160" y="230" font-size="60">',
                    brandInitials,
                '</text>'
            '</svg>'
        );
    }

    function tokenURI(uint tokenId) public view returns (string memory) {
        require(tokenId < websiteFactory.getBlogCount(), "Token does not exist");

        DBlog blog = websiteFactory.blogs(tokenId);

        string memory svg = tokenSVG(tokenId);
        string memory web3Address = tokenWeb3Address(tokenId);
        string memory subdomain = blog.subdomain();
        uint subdomainLength = bytes(subdomain).length;
        string memory extraAttrs = "";
        if(subdomainLength > 0) {
            // Determine character set
            string memory characterSet = "";
            bool isLetterCharacterSet = true;
            bool isNumberCharacterSet = true;
            for(uint i = 0; i < subdomainLength; i++) {
                bytes1 char = bytes(subdomain)[i];
                if(uint8(char) < 97 || uint8(char) > 122) {
                    isLetterCharacterSet = false;
                    break;
                }
                if(uint8(char) < 48 || uint8(char) > 57) {
                    isNumberCharacterSet = false;
                    break;
                }
            }
            if(isLetterCharacterSet) {
                characterSet = "letter";
            }
            else if(isNumberCharacterSet) {
                characterSet = "digit";
            }
            else {
                characterSet = "mixed";
            }
        
            extraAttrs = string.concat(
                ', {'
                    '"trait_type": "Subdomain length", '
                    '"value": ', Strings.toString(subdomainLength),
                '}, {'
                    '"trait_type": "Character set", '
                    '"value": "', characterSet, '"'
                '}'
            );
        }

        return string.concat(
            '{'
                '"id": "', Strings.toString(tokenId), '", '
                '"name": "', web3Address, '", '
                '"description": "A decentralized blog using the web3:// protocol", '
                '"attributes": [{'
                    '"trait_type": "Has subdomain", '
                    '"value": ', (subdomainLength > 0 ? 'true' : 'false'), ''
                '}', extraAttrs, '], '
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),'", '
                '"external_url": "', web3Address, '"'
            '}'
        );
    }
}