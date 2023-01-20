#!/usr/bin/env bash


if [[ ! "$1"  || ! "$2" || ! "$3" || ! "$4" ]]
then
    echo 'Not enough args: need <path to creditcoin-node> <path to chainspec> <path to creditcoin-cli> <path to wasm blob>'
    exit 1
fi

if [[ ! -d "./data" ]]; then
    echo 'Making dir for chain data'
    mkdir data
fi

cc_node="$1"
chainspec="$2"
cc_cli="$3"
wasm_path="$4"

upgraded=false
running=false

node_cmd="$cc_node --chain $chainspec --base-path ./data --validator --mining-threads 1 --mining-key 5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY --execution wasm"

echo 'Starting up the creditcoin node. To see the live logging output, set the environment var PRINT_LOGS to true'
while read -r log_line
do
    if [[ "$PRINT_LOGS" ]]; then
        echo "Log: $log_line"
    fi
    if [[ $running != true ]]; then
        if [[ "$log_line" =~ .*"Successfully mined block".* ]]; then
            echo 'Node is up and running'
            running=true
        fi
    fi
    if [[ $running == true && $upgraded != true ]]; then
        echo 'Upgrading runtime...'
        $cc_cli send-extrinsic set-code "$wasm_path"
        upgraded=true
    fi
    if [[ "$log_line" =~ .*"migrating partially".* ]]; then
        echo "Killing creditcoin node"
        killall -9 creditcoin-node
        echo "Should be broken now! Try running with: $node_cmd"
        exit 0
    fi
done < <($node_cmd 2>&1)
