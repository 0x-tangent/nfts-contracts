#!/bin/bash

mintone()
{
  [ -z $ADDY ] && printf '$ADDY EMPTY\n' && return 0

  seth send --value $(seth --to-wei 0.006 ether) $ADDY 'mint(uint)' 1
}

mintone "$@"
