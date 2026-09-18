/**
 * Enterprise Asset Management System (EAMS)
 * Core Approval Workflow Engine
 * 
 * Supports:
 * - Multi-tier approvals based on amount thresholds
 * - State machine for asset statuses
 * - Rejection and resubmission
 */

const ASSET_STATUS = {
    DRAFT: 'DRAFT',
    PENDING_APPROVAL: 'PENDING_APPROVAL',
    ACTIVE: 'ACTIVE',
    REJECTED: 'REJECTED'
};

const APPROVAL_ROLES = {
    MANAGER: 'Department Manager',
    FINANCE: 'Finance Manager',
    DIRECTOR: 'CFO/Director'
};

class WorkflowEngine {
    
    /**
     * Determine the required approval chain based on the acquisition cost
     * @param {number} amount - Cost of the asset
     * @returns {Array} List of roles required to approve
     */
    static determineApprovalChain(amount) {
        let chain = [APPROVAL_ROLES.MANAGER]; // Always requires direct manager
        
        if (amount > 10000000) {
            // > 10 Juta requires Finance
            chain.push(APPROVAL_ROLES.FINANCE);
        }
        
        if (amount > 100000000) {
            // > 100 Juta requires Director/CFO
            chain.push(APPROVAL_ROLES.DIRECTOR);
        }
        
        return chain;
    }

    /**
     * Submit an asset for approval
     */
    static submitForApproval(asset) {
        if (asset.status !== ASSET_STATUS.DRAFT && asset.status !== ASSET_STATUS.REJECTED) {
            throw new Error("Only Draft or Rejected assets can be submitted.");
        }

        const requiredChain = this.determineApprovalChain(asset.acquisitionCost);
        
        const approvalRequest = {
            id: `REQ-${Date.now()}`,
            assetId: asset.id,
            requestDate: new Date().toISOString(),
            requiredChain: requiredChain,
            currentStep: 0,
            history: [],
            status: 'PENDING'
        };

        asset.status = ASSET_STATUS.PENDING_APPROVAL;
        
        console.log(`[Workflow] Asset ${asset.id} submitted. Required approvals: ${requiredChain.join(' -> ')}`);
        return approvalRequest;
    }

    /**
     * Process an approval action by a specific user role
     */
    static processApproval(approvalRequest, asset, role, action, notes = "") {
        const currentRequiredRole = approvalRequest.requiredChain[approvalRequest.currentStep];
        
        if (role !== currentRequiredRole) {
            throw new Error(`Unauthorized. Awaiting approval from: ${currentRequiredRole}`);
        }

        // Record history
        approvalRequest.history.push({
            role: role,
            action: action, // 'APPROVE' or 'REJECT'
            date: new Date().toISOString(),
            notes: notes
        });

        if (action === 'REJECT') {
            approvalRequest.status = 'REJECTED';
            asset.status = ASSET_STATUS.REJECTED;
            console.log(`[Workflow] Asset ${asset.id} REJECTED by ${role}. Reason: ${notes}`);
            return;
        }

        if (action === 'APPROVE') {
            console.log(`[Workflow] Asset ${asset.id} APPROVED by ${role}.`);
            approvalRequest.currentStep++;

            // Check if workflow is complete
            if (approvalRequest.currentStep >= approvalRequest.requiredChain.length) {
                approvalRequest.status = 'COMPLETED';
                asset.status = ASSET_STATUS.ACTIVE;
                console.log(`[Workflow] Asset ${asset.id} is now FULLY APPROVED and ACTIVE.`);
            } else {
                console.log(`[Workflow] Asset ${asset.id} forwarded to ${approvalRequest.requiredChain[approvalRequest.currentStep]} for next approval.`);
            }
        }
    }
}

// ==========================================
// EXAMPLE USAGE / TEST
// ==========================================
console.log("--- EAMS WORKFLOW SIMULATION ---");

// 1. Create a Draft Asset worth 150 Million (Requires 3-tier approval)
let newAsset = {
    id: 'AST-2026-999',
    name: 'Heavy Excavator',
    acquisitionCost: 150000000, 
    status: ASSET_STATUS.DRAFT
};

// 2. Submit for approval
let request = WorkflowEngine.submitForApproval(newAsset);

// 3. Process Tier 1 (Manager)
WorkflowEngine.processApproval(request, newAsset, APPROVAL_ROLES.MANAGER, 'APPROVE', 'Looks good to me.');

// 4. Process Tier 2 (Finance)
WorkflowEngine.processApproval(request, newAsset, APPROVAL_ROLES.FINANCE, 'APPROVE', 'Budget is available, COA mapped.');

// 5. Process Tier 3 (CFO)
WorkflowEngine.processApproval(request, newAsset, APPROVAL_ROLES.DIRECTOR, 'APPROVE', 'Approved for Capex Q3.');

// Output final state
console.log("\nFinal Asset Status:", newAsset.status);
