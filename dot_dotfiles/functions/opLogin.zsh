# ~/.dotfiles/functions/opLogin.zsh

# Login to 1Password CLI
# ~/.dotfiles/functions/opLogin.zsh
opLogin () {
  # grab the first account’s shorthand – NOT its user_uuid
  local acct=$(op account list --format=json | jq -r '.[0].shorthand')

  # Option A: classic – let 1Password emit the export line
  # eval "$(op signin --account "$acct")"

  # Option B: raw token – do the export yourself
  # export OP_SESSION_${acct}="$(op signin --account "$acct" --raw)"
}
