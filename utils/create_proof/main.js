const { createPublicClient, http, defineChain, keccak256, encodeAbiParameters, parseAbiParameters} = require('viem');

const stylusTestnet = defineChain({
  id: 23011913,
  name: 'Stylus Testnet',
  network: 'stylusTestnet',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH'
  },
  rpcUrls: {
    default: {
      http: [ 'https://stylus-testnet.arbitrum.io/rpc' ]
    },
    public: {
      http: [ 'https://stylus-testnet.arbitrum.io/rpc' ]
    }
  },
  contracts: {
    multicall3: {
      address: '0xcA11bde05977b3631167028862bE2a173976CA11'
    }
  }
})

async function main() {
  const l1BlockNumber = 1;
  const l3BlockNumber = 1044513;
  
  const historyProverAddress = '0xDf859c81287DD1aAcA02d3F56Eaa4dD3C5615EA3';

  const client = createPublicClient({ chain: stylusTestnet, transport: http() });

  const key = keccak256(
    encodeAbiParameters(
      parseAbiParameters('uint256, uint256'),
      [l1BlockNumber, 0]
    )
  );

  const proof = await client.getProof({
    address: historyProverAddress,
    storageKeys: [ key ],
    blockNumber: l3BlockNumber,
  })

  console.log(proof.accountProof);

  console.log(proof.storageProof)

  const block = await client.getBlock({
    blockNumber: l3BlockNumber,
  })

  console.log(block);
}

main().catch(console.error)
