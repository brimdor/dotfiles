# ~/.dotfiles/aliases/nasAliases.zsh
# NAS Dependency Operator management functions

# Switch NAS dependency operator mode with confirmation
nas-mode() {
    local mode="$1"
    local namespace="nas-dependency-operator"
    local resource="nas-workloads"
    
    # Validate mode argument
    if [[ -z "$mode" ]]; then
        echo "Usage: nas-mode <auto|down|up>"
        echo ""
        echo "Modes:"
        echo "  auto  - Normal operation, operator monitors NAS health"
        echo "  down  - Manual maintenance: scales down workloads, cordons/drains nodes"
        echo "  up    - Manual restore: scales up workloads, uncordons nodes"
        echo ""
        echo "Current status:"
        kubectl get nasdependency "$resource" -n "$namespace" 2>/dev/null || echo "  (unable to reach cluster)"
        return 1
    fi
    
    # Validate mode value
    if [[ ! "$mode" =~ ^(auto|down|up)$ ]]; then
        echo "Error: Invalid mode '$mode'. Must be one of: auto, down, up"
        return 1
    fi
    
    # Get current state
    local current_mode current_phase nas_available workloads nodes
    current_mode=$(kubectl get nasdependency "$resource" -n "$namespace" -o jsonpath='{.spec.mode}' 2>/dev/null)
    current_phase=$(kubectl get nasdependency "$resource" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)
    nas_available=$(kubectl get nasdependency "$resource" -n "$namespace" -o jsonpath='{.status.nasAvailable}' 2>/dev/null)
    workloads=$(kubectl get nasdependency "$resource" -n "$namespace" -o jsonpath='{.status.managedWorkloads}' 2>/dev/null)
    nodes=$(kubectl get nasdependency "$resource" -n "$namespace" -o jsonpath='{.status.managedNodes}' 2>/dev/null)
    
    if [[ -z "$current_mode" ]]; then
        echo "Error: Unable to get current NASDependency state. Is the cluster reachable?"
        return 1
    fi
    
    # Check if already in desired mode
    if [[ "$current_mode" == "$mode" ]]; then
        echo "Already in '$mode' mode. No change needed."
        return 0
    fi
    
    # Display current state and what will happen
    echo "Current State:"
    echo "  Mode:          $current_mode"
    echo "  Phase:         $current_phase"
    echo "  NAS Available: $nas_available"
    echo "  Workloads:     $workloads"
    echo "  Nodes:         ${nodes:-0}"
    echo ""
    
    # Warn about consequences
    case "$mode" in
        down)
            echo "WARNING: Setting mode to 'down' will:"
            echo "  1. Cordon all UNRAID virtual nodes (virtual0, virtual1)"
            echo "  2. Drain all pods from those nodes"
            echo "  3. Scale down all $workloads NAS-dependent workloads to 0 replicas"
            echo ""
            ;;
        up)
            echo "Setting mode to 'up' will:"
            echo "  1. Restore all workloads to their original replica counts"
            echo "  2. Uncordon all managed nodes"
            echo "  3. Trigger ArgoCD sync (if configured)"
            echo ""
            ;;
        auto)
            echo "Setting mode to 'auto' will:"
            echo "  1. Resume automatic NAS health monitoring"
            echo "  2. Operator will manage state based on NAS availability"
            echo ""
            ;;
    esac
    
    # Confirmation prompt
    echo -n "Change mode from '$current_mode' to '$mode'? [y/N] "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        return 1
    fi
    
    # Apply the change
    echo ""
    echo "Applying mode change..."
    if ! kubectl patch nasdependency "$resource" -n "$namespace" \
        --type=merge -p "{\"spec\":{\"mode\":\"$mode\"}}"; then
        echo "Error: Failed to patch NASDependency"
        return 1
    fi
    
    echo ""
    echo "Waiting for phase to stabilize..."
    echo ""
    
    # Determine target phase based on mode
    local target_phase
    case "$mode" in
        down) target_phase="ScaledDown" ;;
        up|auto) target_phase="Running" ;;
    esac
    
    # Poll until phase stabilizes (max 5 minutes)
    local timeout=300
    local interval=3
    local elapsed=0
    local phase=""
    
    while [[ $elapsed -lt $timeout ]]; do
        phase=$(kubectl get nasdependency "$resource" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)
        
        # Show current status
        kubectl get nasdependency "$resource" -n "$namespace" --no-headers 2>/dev/null
        
        # Check if we've reached target phase
        if [[ "$phase" == "$target_phase" ]]; then
            echo ""
            echo "Done! Phase stabilized at '$target_phase'."
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    echo ""
    echo "Warning: Timed out waiting for phase to reach '$target_phase' (current: $phase)"
    echo "The operation may still be in progress. Check with: nas-status"
    return 1
}

# Quick status check alias
alias nas-status='kubectl get nasdependency nas-workloads -n nas-dependency-operator && echo "" && echo "Managed Nodes:" && kubectl get nodes -l homelab.eaglepass.io/hypervisor=unraid -o wide'
