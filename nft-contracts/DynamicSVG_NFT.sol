// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DynamicSVG_NFT is ERC721 {
    uint256 private tokenCounter;
    string private lowImageURI;
    string private highImageURI;
    AggregatorV3Interface internal immutable priceFeed;
    mapping(uint256 => int256) public tokenIdToHighValue;
    event CreatedNFT(uint256 indexed tokenId, int256 highValue);

    constructor(
        address priceFeedAddress,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("DynamicSVG_NFT", "DSN") {
        tokenCounter = 0;
        lowImageURI = svgToImageURI(lowSvg);
        highImageURI = highSvg;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function mintNft(int256 highValue) public {
        uint256 newTokenId = tokenCounter;
        tokenIdToHighValue[newTokenId] = highValue;
        tokenCounter++;
        _safeMint(msg.sender, newTokenId);
        emit CreatedNFT(newTokenId, highValue);
    }

    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        string memory baseURL = "";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        // require()
        (, int256 price, , , ) = priceFeed.latestRoundData();
        string memory imageURI = lowImageURI;
        if (price >= tokenIdToHighValue[tokenId]) {
            imageURI = highImageURI;
        }
        return
            string(
                abi.encodePacked(
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name ":',
                                name(),
                                '", "description": "An NFT that changes based on Chainlink Feed',
                                '"attributes": [{"trait_type": "coolness", "value" : 100}], "image:"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
