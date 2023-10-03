//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleAAv4 {
    address public owner;
    address proposed_new_owner;
    //uint128 change_proposal_number;
    AgentInfo[] public agents_record;

    struct AgentInfo {
        address addr;
        bool b_agent;
        bool b_owner_change_approval;
    }

    //uint256 public numAgent;
    function numAgent() public returns (uint256) {
        (bool _nouse, uint256 num_result) = agentArrayOps(AgentOps.COUNT_AGENTS, address(0));
        return num_result;
    }

    enum AgentOps {
        FIND_AGENT_IDX,
        COUNT_APPROVE,
        RESET_APPROVE,
        COUNT_AGENTS
    }

    function agentArrayOps(AgentOps ops, address _addr) internal returns (bool success, uint256 num_result) {
        for (uint256 i = 0; i < agents_record.length; i++) {
            if (agents_record[i].b_agent) {
                if (ops == AgentOps.FIND_AGENT_IDX) {
                    // agentArrayOps(AgentOps.FIND_AGENT_IDX, _addr)
                    if (agents_record[i].addr == _addr) {
                        success = true;
                        num_result = i;
                        break;
                    }
                } else if (ops == AgentOps.COUNT_AGENTS) {
                    ++num_result;
                } else if (ops == AgentOps.COUNT_APPROVE) {
                    if (agents_record[i].b_owner_change_approval) {
                        // agentArrayOps(AgentOps.COUNT_APPROVE, address(0))
                        num_result++;
                    }
                } else if (ops == AgentOps.RESET_APPROVE) {
                    // agentArrayOps(AgentOps.RESET_APPROVE, address(0))
                    agents_record[i].b_owner_change_approval = false;
                }
            }
        }
    }

    function min_agent_approval() public returns (uint256 aa) {
        aa = numAgent();
        return aa - aa / 3;
    }

    error NewOwnerAddressMisMatch();
    error OnlyAgentCanProposeNewOwner();

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyAgent() {
        //(bool success,) = findAgent(msg.sender);
        (bool success,) = agentArrayOps(AgentOps.FIND_AGENT_IDX, msg.sender);
        require(success == true, "only agent can change owner!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can add new agent");
        _;
    }

    receive() external payable {}

    function addAgent(address new_agent) external onlyOwner returns (bool) {
        //(bool success, uint256 pos_index) = findAgent(new_agent);
        (bool success, uint256 pos_index) = agentArrayOps(AgentOps.FIND_AGENT_IDX, new_agent);
        if (success) {
            agents_record[pos_index].b_agent = true;
        } else {
            agents_record.push(AgentInfo(new_agent, true, false));
        }
        return true;
    }

    function removeAgent(address new_agent) external onlyOwner returns (bool) {
        //(bool success, uint256 pos_index) = findAgent(new_agent);
        (bool success, uint256 pos_index) = agentArrayOps(AgentOps.FIND_AGENT_IDX, new_agent);
        if (success) {
            agents_record[pos_index].b_agent = false;
        }
        return success; // already removed or not there.
    }

    //needs 2/3 agents vote to change owner.
    function proposeChangeOwner(address new_owner) external returns (bool) {
        require(new_owner != owner, "the address is already owner!");

        //(bool success, uint256 pos_index) = findAgent(msg.sender);

        (bool success, uint256 pos_index) = agentArrayOps(AgentOps.FIND_AGENT_IDX, msg.sender);

        if (success) {
            proposed_new_owner = new_owner; // only proposed, still need approval of 2/3 people;
            //resetChangeProposal();
            //numAgentApprovedChange(true);
            agentArrayOps(AgentOps.RESET_APPROVE, address(0));
            agents_record[pos_index].b_owner_change_approval = true;
        } else {
            revert OnlyAgentCanProposeNewOwner();
            // require(false, "OnlyAgentCanProposeNewOwner");
        }
        return success;
    }

    function approveProposedOwner(address new_owner) external returns (uint256) {
        if (new_owner != proposed_new_owner) {
            //error address mismatch.
            revert NewOwnerAddressMisMatch();
        }

        //(bool success, uint256 pos_index) = findAgent(msg.sender);
        (bool success, uint256 pos_index) = agentArrayOps(AgentOps.FIND_AGENT_IDX, msg.sender);

        if (success) {
            agents_record[pos_index].b_owner_change_approval = true;

            uint256 min_approval = min_agent_approval();
            (bool _noneed, uint256 change_proposal_number) = agentArrayOps(AgentOps.COUNT_APPROVE, address(0));

            //uint256 change_proposal_number = numAgentApprovedChange(false);
            if (change_proposal_number >= min_approval) {
                owner = proposed_new_owner;
                proposed_new_owner = address(0);
                agentArrayOps(AgentOps.RESET_APPROVE, address(0));
                //numAgentApprovedChange(true);
                return 0;
            } else {
                return min_approval - change_proposal_number;
            }
        } else {
            revert OnlyAgentCanProposeNewOwner();
            //require(false, "OnlyAgentCanProposeNewOwner");
        }
    }

    /*     function resetChangeProposal() private onlyAgent {
        for (uint256 i = 0; i < agents_record.length; i++) {
            agents_record[i].b_owner_change_approval = false;
        }
    } */
}
