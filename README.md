# Interrupted Migration Bug

This repo is for reproducing a bug where migrations being interrupted before completion
cause the node to hang indefinitely once it starts again.

## Clone this repo

NOTE: You'll need [git lfs](https://git-lfs.com) to clone the creditcoin repo with the necessary chainspec (which is ~1GiB and too large for plain git).

Since this repo uses submodules, you'll want to clone it with

```bash
git clone --recurse-submodules https://github.com/nathanwhit/cc-interrupted-migration-repro
```

## Reproduction

1. Build the creditcoin node (and runtime) from the creditcoin directory in this repo (it's a git submodule pointing to [this branch](https://github.com/gluwa/creditcoin/tree/multi-block-migration-testing))
    - Basically just `cd creditcoin; cargo build --release` assuming you have the dependencies met already
2. Run a node using the chainspec `migrateTestSpec.json`

    ```bash
    # for the chain data
    mkdir data
    ./creditcoin/target/release/creditcoin-node --chain ./creditcoin/chainspecs/migrateTestSpec.json\
        --base-path ./data --validator --mining-threads 1\
        --mining-key 5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY --execution wasm
    ```

3. Wait for the node to mine blocks (should see logs like `Successfully mined block on top of: 0xdca6…c5d8`)
4. Send the runtime upgrade
    - You can do this manually through the [polkadotJS explorer](https://polkadot.js.org/apps/?rpc=ws%3A%2F%2F127.0.0.1%3A9944#/explorer)
    or with the `creditcoin-cli` tool in this repo: [docs](./creditcoin-cli/README.md#sending-a-runtime-upgrade-to-a-local-node)
5. Wait for logs indicating the runtime migration is in-progress
    - Look for messages like "Moved DealOrders!", "Moved AskOrders!"
6. Forcefully kill the node

    ```bash
    killall -9 creditcoin-node
    ```

7. Re-run the node and observe that it doesn't successfully mine blocks or progress past the migration

I've also included a [bash script](./break-node.sh) in this repo to perform steps 2-6 that you can run like so:

```bash
./break-node.sh ./creditcoin/target/release/creditcoin-node ./creditcoin/chainspecs/migrateTestSpec.json ./creditcoin-cli/target/release/creditcoin-cli ./creditcoin/target/release/wbuild/creditcoin-node-runtime/creditcoin_node_runtime.compact.compressed.wasm
```
