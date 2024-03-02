import { Alchemy, Network } from "alchemy-sdk";

const config = {
  apiKey: "CHSK86m4Q9RWyWaW6N_RB-IXHQZ663My",
  network: Network.ETH_SEPOLIA,
};
const alchemy = new Alchemy(config);

export async function getTxHashInBlockRange(
  address: string,
  start: number,
  end: number,
  order: 'asc' | 'desc'
): Promise<{ hash: string; block: string } | null> {
  /* @ts-ignore */
  const result = await alchemy.core.getAssetTransfers({
    fromBlock: start,
    toBlock: end,
    fromAddress: address,
    category: ["external", "internal", "erc20", "erc721", "erc1155"],
    excludeZeroValue: false,
    maxCount: "0x1",
    order,
  });

  if (result.transfers.length == 0) return null; // todo manage the NO TX Case

  const t = result.transfers[0];
  return { hash: t.hash, block: t.blockNum };
}
