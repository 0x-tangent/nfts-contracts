#!/bin/bash

deploynew()
{
  [ -z "$1" ] && contract_name="Alphabet" || contract_name="$1"
  . .sethrc

  dapp build
  dapp create "$contract_name"
}

deploynew "$@"
