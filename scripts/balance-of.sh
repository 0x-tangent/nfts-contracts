#!/bin/bash

balanceof()
{
  [ -z $ADDY ] && printf '$ADDY EMPTY\n' && return 0
  [ -z $1    ] && my="$aa" || my="$1"

  seth call $ADDY 'balanceOf(address)(uint)' "$my"
}

balanceof "$@"

