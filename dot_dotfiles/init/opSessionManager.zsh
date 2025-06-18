# ~/.dotfiles/functions/opSessionManager.zsh

# 1Password Session Manager
op_session_manager() {
  local session_dir="$HOME/.op_sessions"
  mkdir -p "$session_dir"
  chmod 700 "$session_dir"

  # Function to retrieve the account alias (user UUID)
  get_account_alias() {
    op account list --format json | jq -r '.[0].user_uuid'
  }

  # Function to sign in and manage the session token
  signin_op() {
    local account_alias="$1"
    local session_file="$2"
    local session_token

    # Check if the session file exists
    if [[ -f "$session_file" ]]; then
      session_token=$(<"$session_file")
      export OP_SESSION_"$account_alias"="$session_token"

      # Verify if the session token is still valid using `op account get`
      if op account get >/dev/null 2>&1; then
        echo "✅ 1Password session for account $account_alias is active."
        return 0
      else
        echo "⚠️ 1Password session for account $account_alias is invalid or expired. Re-authenticating..."
        rm -f "$session_file"
      fi
    fi

    # Proceed to sign in if session is missing or invalid
    # echo "🔑 Signing in to 1Password account $account_alias..."
    session_token=$(op signin --account "$account_alias" --raw)

    if [[ -z "$session_token" ]]; then
      echo "❌ 1Password sign-in failed. Please check your credentials."
      return 1
    fi

    # Save the session token to the session file
    echo "$session_token" > "$session_file"
    chmod 600 "$session_file"

    # Export the session token
    export OP_SESSION_"$account_alias"="$session_token"

    echo "✅ Signed in to 1Password account $account_alias successfully."
  }

  # Retrieve the account alias
  local account_alias
  account_alias=$(get_account_alias)

  if [[ -z "$account_alias" ]]; then
    echo "❌ Unable to retrieve 1Password account alias."
    return 1
  fi

  # Define the session file path
  local session_file="$session_dir/session_$account_alias"

  # Handle sign-in with checks within signin_op
  signin_op "$account_alias" "$session_file"
}

# Initialize the 1Password session manager
op_session_manager
