package main

import (
	"bytes"
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rlp"
)

func main() {
  ctx := context.Background()
  client, err := ethclient.Dial("https://mainnet.infura.io/v3/fe615a739b56483f84597cd983434259")
  if err != nil {
    panic(err)
  }

  block, err := client.BlockByNumber(ctx, big.NewInt(1_000_000))
  if err != nil {
    panic(err)
  }

  buf := &bytes.Buffer{}

  fmt.Println(block.Header())

  if err := rlp.Encode(buf, block.Header()); err != nil {
    panic(err)
  }

  fmt.Println(hexutil.Encode(buf.Bytes()))
  fmt.Println(block.Header().Hash())
}
