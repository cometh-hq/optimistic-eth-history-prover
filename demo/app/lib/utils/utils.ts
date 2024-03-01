export const shortenEthAddress = (address: string) => {
  const s = address?.toString();
  return `${s?.substring(0, 6)}...${s?.substring(42 - 4)}`;
}
