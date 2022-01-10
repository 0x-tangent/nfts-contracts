#!/bin/bash

function debuglast()
{
  . .sethrc

  [ -z $ADDY ] && printf '$ADDY EMPTY\n' && return 0

  seth run-tx --debug $(lastTx) --source=./out/dapp.sol.json
}

debuglast "$@"
