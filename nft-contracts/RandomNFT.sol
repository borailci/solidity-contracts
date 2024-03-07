// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // extends ERC721
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNFT is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    enum Baller {
        THEO,
        MARTINEZ,
        SERDAR
    }

    // VRF variables

    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    mapping(uint256 => address) private requestAddress;
    bytes32 private immutable keyHash;
    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Token variables

    uint private tokenCounter;
    string[] internal tokenURIs;
    uint256 private immutable mintFee;

    event NftRequested(uint256 indexed requestId, address indexed requester);
    event NftMinted(
        uint256 indexed tokenId,
        Baller indexed baller,
        address indexed minter
    );

    // Functions
    constructor(
        address vrfCoordinatorV2,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _mintFee,
        string[3] memory _tokenURIs
    )
        VRFConsumerBaseV2(vrfCoordinatorV2)
        ERC721("Ballers", "BLR")
        Ownable(msg.sender)
    {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        tokenCounter = 0;
        mintFee = _mintFee;
        tokenURIs = _tokenURIs;
    }

    function requestNFT() public payable returns (uint256 requestID) {
        if (msg.value < mintFee) {
            revert("Insufficient ETH Sent");
        }

        requestID = vrfCoordinator.requestRandomWords(
            keyHash, // The gas lane key hash value, which is the maximum gas price you are willing to pay for a request in wei.
            subscriptionId, // The subscription ID that this contract uses for funding requests.
            REQUEST_CONFIRMATIONS, // How many confirmations the Chainlink node should wait before responding.
            callbackGasLimit, // The limit for how much gas to use for the callback request to your contract's fulfillRandomWords() function.
            NUM_WORDS // How many random values to request.
        );
        requestAddress[requestID] = msg.sender;
        emit NftRequested(requestID, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestID,
        uint256[] memory randomWords
    ) internal override {
        address owner = requestAddress[requestID];
        uint256 tokenId = tokenCounter;
        tokenCounter++;
        uint256 dice = randomWords[0] % 100;
        Baller baller = getBallerType(dice);
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, tokenURIs[uint256(baller)]);
        emit NftMinted(tokenId, baller, owner);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert("Transaction Failure");
    }

    function getBallerType(uint256 dice) public pure returns (Baller) {
        if (0 <= dice && dice < 10) return Baller.THEO;
        else if (10 <= dice && dice < 40) return Baller.MARTINEZ;
        else if (40 <= dice && dice < 100) return Baller.SERDAR;
        else revert("Invalid Dice Value");
    }

    function getMintFee() public view returns (uint256) {
        return mintFee;
    }

    function getTokenCounter() public view returns (uint256) {
        return tokenCounter;
    }

    function getTokenURIs(uint256 index) public view returns (string memory) {
        return tokenURIs[index];
    }
}
