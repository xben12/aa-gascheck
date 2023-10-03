//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleAAv5 {
    address public owner;
    mapping(address => AgentInfo) agents; // it is here you double save the info.
    uint256 public numAgent;

    struct AgentInfo {
        bool b_agent;
        bool b_owner_change_approval;
    }

    address[] change_owners;

    function min_agent_approval() public view returns (uint256) {
        return numAgent - numAgent / 3;
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
        if (agents[new_agent].b_agent == false) {
         agents[new_agent] = AgentInfo(true, false);
        numAgent++;
        return true;           
        } else {
return false; // already added.
        }

    }

    function removeAgent(address new_agent) external onlyOwner returns (bool) {
        if (agents[new_agent].b_agent == false) {
            return false; // already removed or not there.
        }

        agents[new_agent].b_agent = false;
        numAgent--;
        return true;
    }

    //needs 2/3 agents vote to change owner.
    function proposeChangeOwner(address new_owner) external onlyAgent returns (bool) {
        require(new_owner != owner, "the address is already owner!");
        if (change_owners.length != 0) {
            resetChangeProposal();
        }
        change_owners.push(new_owner); // always at 0 position.
        change_owners.push(msg.sender); // need to push both into array.
        agents[msg.sender].b_owner_change_approval = true;
        return true;
    }

    function approveProposedOwner(address new_owner) external onlyAgent returns (uint256) {
        if (new_owner != change_owners[0]) {
            //error address mismatch.
            revert NewOwnerAddressMisMatch();
        }

        if (agents[msg.sender].b_owner_change_approval == false) {
            agents[msg.sender].b_owner_change_approval = true;
            change_owners.push(msg.sender);
        }

        uint256 still_need = min_agent_approval() - (change_owners.length - 1);

        if (still_need <= 0) {
            // may have overflow revert
            owner = change_owners[0];
            resetChangeProposal();
            return 0;
        } else {
            return still_need;
        }
    }

    function resetChangeProposal() private onlyAgent {
            for (uint256 i = 1; i < change_owners.length; i++) {
                agents[change_owners[i]].b_owner_change_approval = false;
            }
            delete change_owners;
    }
}
