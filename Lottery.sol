// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Lottery is VRFConsumerBaseV2 {
    // Errors
    error Lottery__NotEnoughETH(); // At least 0.01 eth to join.
    error Lottery__AlreadyParticipated(); // Every participant can only join the lottery once.
    error Lottery__TransactionFailure();
    error Lottery__HistoryDoesNotExist();
    // Events
    event enteredLottery(address indexed participantAddress);
    event winnerPicked(address indexed winnerAddress);

    // Lottery Contract Variables
    uint256 public constant enteranceFee = 10000000000000000 wei; // 0.1 ether
    address private immutable owner;
    uint256 public lotteryId;
    mapping(uint256 => address) private history;
    address payable[] public participants;
    // Random Generator Contract Constructor Variables
    bytes32 private immutable keyHash;
    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address private constant vrfCoordinatorV2 =
        0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    VRFCoordinatorV2Interface private immutable vrfCoordinator;

    // Functions
    constructor() VRFConsumerBaseV2(vrfCoordinatorV2) {
        owner = msg.sender;
        lotteryId = 1;
        keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        subscriptionId = 9642;
        callbackGasLimit = 2500000;
        vrfCoordinator = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
    }

    function check_history(uint256 id) public view returns (address) {
        // revert error if not exist
        if (history[id] == 0x0000000000000000000000000000000000000000)
            revert Lottery__HistoryDoesNotExist();
        return history[id];
    }

    function enterLottery() public payable {
        if (msg.value < enteranceFee) revert Lottery__NotEnoughETH();
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == msg.sender)
                revert Lottery__AlreadyParticipated();
        }
        participants.push(payable(msg.sender));
        emit enteredLottery(msg.sender);
    }

    function fulfillRandomWords(
        // This function is overwritten from VRF. It takes randomWords as a parameter from requestRandomWords() so we can use the random number in our lottery.
        uint256, //requestId, we do not use this but contract has to take it as a parameter.
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % participants.length;
        address payable winner = participants[winnerIndex];
        history[lotteryId++] = winner;
        participants = new address payable[](0);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Lottery__TransactionFailure();
        emit winnerPicked(winner);
    }

    function pickWinner() public onlyOwner {
        vrfCoordinator.requestRandomWords( // This function is also uses VRF contract. It requests verified random numbers from Chainlink.
            keyHash, // The gas lane key hash value, which is the maximum gas price we are willing to pay for a request in wei.
            subscriptionId, // The subscription ID that this contract uses for funding requests.
            REQUEST_CONFIRMATIONS, // How many confirmations the Chainlink node should wait before responding.
            callbackGasLimit, // The limit for how much gas to use for the callback request to your contract's fulfillRandomWords() function.
            NUM_WORDS // How many random values to request.
        );
    }

    function withdraw() public payable onlyOwner {
        // Withdraws all the ETH storaged in the contract. Only owner can use.
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert Lottery__TransactionFailure();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access!");
        _;
    }
}
