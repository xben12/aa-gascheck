//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleAAv2 {
    address public owner;
    address proposed_new_owner;

    mapping(address => AgentInfo) agents; // it is here you double save the info.
    address[] public agents_record;

    uint256 private num_removed_agent;
    uint256 change_proposal_number;

    struct AgentInfo {
        bool b_agent;
        bool b_owner_change_approval;
    }

    //uint256 public numAgent;
    function numAgent() public view returns (uint256) {
        return agents_record.length - num_removed_agent;
    }

    function min_agent_approval() public view returns (uint256) {
        uint256 aa = agents_record.length - num_removed_agent;
        return aa - aa / 3;
    }

    error NewOwnerAddressMisMatch();

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyAgent() {
        require(agents[msg.sender].b_agent == true, "only agent can change owner!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can add new agent");
        _;
    }

    receive() external payable {}

    function addAgent(address new_agent) external onlyOwner returns (bool) {
        if (agents[new_agent].b_agent == true) {
            return false; // already added.
        }
        agents[new_agent] = AgentInfo(true, false);
        agents_record.push(new_agent);
        return true;
    }

    function removeAgent(address new_agent) external onlyOwner returns (bool) {
        if (agents[new_agent].b_agent == false) {
            return false; // already removed or not there.
        }

        agents[new_agent].b_agent = false;
        num_removed_agent = num_removed_agent + 1;
        return true;
    }

    //needs 2/3 agents vote to change owner.
    function proposeChangeOwner(address new_owner) external onlyAgent returns (bool) {
        require(new_owner != owner, "the address is already owner!");
        proposed_new_owner = new_owner; // only proposed, still need approval of 2/3 people;
        resetChangeProposal();
        agents[msg.sender].b_owner_change_approval = true;
        change_proposal_number = 1;
        return true;
    }

    function approveProposedOwner(address new_owner) external onlyAgent returns (uint256) {
        if (new_owner != proposed_new_owner) {
            //error address mismatch.
            revert NewOwnerAddressMisMatch();
        }

        if (agents[msg.sender].b_owner_change_approval == false) {
            agents[msg.sender].b_owner_change_approval = true;
            change_proposal_number = change_proposal_number + 1;
        }

        uint256 min_approval = min_agent_approval();
        if (change_proposal_number >= min_approval) {
            owner = proposed_new_owner;
            resetChangeProposal();
            return 0;
        } else {
            return min_approval - change_proposal_number;
        }
    }

    function resetChangeProposal() private onlyAgent {
        if (change_proposal_number > 0) {
            // need to delete all
            for (uint256 i = 0; i < agents_record.length; i++) {
                agents[agents_record[i]].b_owner_change_approval = false;
            }
            change_proposal_number = 0;
        }
    }
}
