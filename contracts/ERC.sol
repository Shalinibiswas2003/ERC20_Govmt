// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC is ERC20 {
    address public admin;
    IERC20 public token;  // ERC20 interface token used for voting

    uint256 public proposalCount;  // keeps track of No of proposals
    uint256 public votingEndTime = block.timestamp; 
     // End time of the voting period
    uint256 public Now;

    constructor(uint256 initialSupply) ERC20("Token", "GVMT") {
        _mint(msg.sender, initialSupply); // Mint initial supply to sender
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admins can access");
        _;
    }

    enum ProposalStatus { Pending, Approved, Rejected }

    struct Proposal {
        uint256 id;               // Unique identifier for the proposal
        address proposer;         // Address of the proposal submitter
        string description;       // Description or details of the proposal
        uint256 forVotes;         // Total votes in favor of the proposal
        uint256 againstVotes;     // Total votes against the proposal
        ProposalStatus status;    // Current status of the proposal
        mapping(address => bool) voted;  // Tracks if the address has voted or not
    }

    mapping(uint256 => Proposal) public proposals;  // Storing the proposals

    event ProposalCreated(uint256 id, address indexed proposer, string desc);
    event Voted(uint256 indexed proposalId, address indexed voter, bool forVote);
    event ProposalExecuted(uint256 indexed proposalId, uint256 forVotes, uint256 againstVotes);
   
   
    modifier duringVotingPeriod() {
       
        require(block.timestamp < votingEndTime, "Voting period has ended");
        _;
    }

    function createProposal(string memory _description) external onlyAdmin duringVotingPeriod {
        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.status = ProposalStatus.Pending;

        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function vote(uint256 proposalId, bool inSupport) external duringVotingPeriod {
        Proposal storage proposal = proposals[proposalId];
        
        

        require(!proposal.voted[msg.sender], "Already voted");

        // Require a minimum balance of tokens for voting (adjust as needed)
        require(balanceOf(msg.sender) > 0, "Insufficient tokens for voting");

        if (inSupport) {
            proposal.forVotes += balanceOf(msg.sender);
        } else {
            proposal.againstVotes += balanceOf(msg.sender);
        }

        proposal.voted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, inSupport);
    }

    function executeProposal(uint256 proposalId) external onlyAdmin duringVotingPeriod {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not pending");

        if (proposal.forVotes > proposal.againstVotes) {
            // Proposal is approved
            proposal.status = ProposalStatus.Approved;
            emit ProposalExecuted(proposalId, proposal.forVotes, proposal.againstVotes);

            // Implement the action of the proposal here
            // Example: interact with other contracts, update state, etc.
        } else {
            // Proposal is rejected
            proposal.status = ProposalStatus.Rejected;
        }
    }

    function setVotingPeriod(uint256 _durationInSeconds) external onlyAdmin {
        // Allow the admin to set a new voting period
        votingEndTime = block.timestamp + _durationInSeconds;
    }
}
