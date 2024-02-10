// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract VotingContract {
    // Errors
    error VotingContract__AlreadyCandidate();
    error VotingContract__CandidateNotExist();
    error VotingContract__AlreadyVotedOnce();
    error VotingContract__AgeUnder18();
    error VotingContract__invalidGender();

    // Enums
    enum Gender {
        MAN,
        WOMAN
    }

    // Structs
    struct Person {
        string name;
        string surname;
        uint256 age;
        Gender gender;
    }

    // Variables
    address private immutable owner;
    address[] private candidates;
    mapping(address => uint) private votes;
    mapping(address => Person) private voters;
    mapping(address => uint) private didVote;
    // Events
    event Vote();

    // Functions
    constructor() {
        owner = msg.sender;
    }

    function setCandidates(
        address candidate,
        string memory _name,
        string memory _surname,
        uint256 _age,
        Gender _gender
    ) public onlyOwner {
        if (_age < 18) revert VotingContract__AgeUnder18();
        if (_gender != Gender.MAN && _gender != Gender.WOMAN)
            revert VotingContract__invalidGender();
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == candidate)
                revert VotingContract__AlreadyCandidate();
        }
        candidates.push(candidate);
        votes[candidate] = 0;
        voters[candidate] = Person({
            name: _name,
            surname: _surname,
            age: _age,
            gender: _gender
        });
    }

    function getVotes(address candidate) public view returns (uint256) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == candidate) {
                return votes[candidate];
            }
        }
        revert VotingContract__CandidateNotExist();
    }

    function vote(address candidate) public {
        if (didVoted[msg.sender] == 1)
            revert VotingContract__AlreadyVotedOnce();
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == candidate) {
                votes[candidate]++;
                didVoted[msg.sender] = 1;
                emit Vote();
                return;
            }
        }
        revert VotingContract__CandidateNotExist();
    }

    // Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Unauthorized access attempt");
        _;
    }
}
