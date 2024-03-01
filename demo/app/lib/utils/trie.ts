import RLP from "rlp";
import { toHex } from "viem";
import { ethers } from "ethers";
import level from "level-mem";
import { BaseTrie as Trie } from "merkle-patricia-tree";

const db = level();

function parseTx(tx: any) {
  const converted = {
    ...tx,
    data: tx.input,
    type: parseInt(tx.type, 16),
    gasLimit: tx.gas,
    signature: ethers.Signature.from({
      r: tx.r,
      s: tx.s,
      v: tx.v,
    }),
  };
  return ethers.Transaction.from(converted);
}

export async function computeTxMerkleTrie(block: any) {
  const trie = new Trie(db);

  for (const tx of block.transactions) {
    const key = toHex(RLP.encode(parseInt(tx.transactionIndex, 16)));

    const value = parseTx(tx).serialized;
    //console.log("txHash:", transaction.hash);
    //  console.log("value:", value);
    await trie.put(
      Buffer.from(key.slice(2), "hex"),
      Buffer.from(value.slice(2), "hex")
    );
  }

  return trie;
}
