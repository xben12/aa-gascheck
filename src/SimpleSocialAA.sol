//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleSocialAA {
    address public owner;
    mapping(address => bool) agents;
    address[] public agents_record;
    uint256 public agents_number;
    uint256 constant min_agent_num = 2;
    uint256 public min_agent_approval = min_agent_num;

    address proposed_new_owner;
    mapping(address => bool) change_proposal; // hold the people already submitted change.
    address[] private change_proposal_address_list;
    uint256 change_proposal_number;

    error NewOwnerAddressMisMatch();

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyAgent() {
        require(agents[msg.sender] == true, "only agent can change owner!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can add new agent");
        _;
    }

    receive() external payable {}

    function addAgent(address new_agent) public onlyOwner returns (bool) {
        if (agents[new_agent] == true) {
            return false; // already added.
        }

        agents[new_agent] = true;
        agents_record.push(new_agent);
        agents_number = agents_number + 1;

        min_agent_approval = (agents_number * 2 + 2) / 3;
        if (min_agent_approval < min_agent_num) {
            min_agent_approval = min_agent_num;
        }
        return true;
    }

    function removeAgent(address new_agent) public onlyOwner returns (bool) {
        if (agents[new_agent] == false) {
            return false; // already removed or not there.
        }

        agents[new_agent] = false;
        uint256 i;
        for (i = 0; i < agents_number; i++) {
            if (agents_record[i] == new_agent) {
                break;
            }
        }
        require(i < agents_number, "Data error: Agent in Map but not in array record. ");
        for (uint256 j = i + 1; j < agents_number; j++) {
            agents_record[j - 1] = agents_record[j];
        }
        agents_record.pop();
        agents_number = agents_number - 1;

        min_agent_approval = (agents_number * 2 + 2) / 3;
        if (min_agent_approval < min_agent_num) {
            min_agent_approval = min_agent_num;
        }
        return true;
    }

    //needs 2/3 agents vote to change owner.
    function proposeChangeOwner(address new_owner) public onlyAgent returns (bool) {
        require(new_owner != owner, "the address is already owner!");
        proposed_new_owner = new_owner; // only proposed, still need approval of 2/3 people;
        resetChangeProposal();
        change_proposal_number = 1;
        return true;
    }

    function approveProposedOwner(address new_owner) public onlyAgent returns (uint256) {
        if (new_owner != proposed_new_owner) {
            //error address mismatch.
            revert NewOwnerAddressMisMatch();
        }

        if (change_proposal[msg.sender] == false) {
            change_proposal[msg.sender] = true;
            change_proposal_number = change_proposal_number + 1;
        }

        if (change_proposal_number >= min_agent_approval) {
            owner = proposed_new_owner;
            resetChangeProposal();
            return 0;
        } else {
            // not enough approvals.
            uint256 still_need_num = min_agent_approval - change_proposal_number;
            return still_need_num;
        }
    }

    function resetChangeProposal() private onlyAgent {
        if (change_proposal_address_list.length > 0) {
            // need to delete all
            for (uint256 i = 0; i < change_proposal_address_list.length; i++) {
                change_proposal[change_proposal_address_list[i]] = false;
            }
            delete change_proposal_address_list;
        }
    }
}
