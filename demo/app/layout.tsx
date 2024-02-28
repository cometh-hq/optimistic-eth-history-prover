"use client";

import "./globals.css";
import { WagmiProvider, createConfig } from "wagmi";
import { arbitrumSepolia, mainnet } from "viem/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ConnectKitProvider, getDefaultConfig } from "connectkit";

const chains = [arbitrumSepolia, mainnet];

const config = createConfig(
  /* @ts-ignore */
  getDefaultConfig({
    /* @ts-ignore */
    chains,
    walletConnectProjectId: "5aeb98cffaa638c1f864f7afaf366e29",
  })
);

const queryClient = new QueryClient();

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            <ConnectKitProvider>{children}</ConnectKitProvider>
          </QueryClientProvider>
        </WagmiProvider>
      </body>
    </html>
  );
}
