import { Route, Routes } from "react-router-dom";

import Navbar from "./pages/Navbar";
import Mint from "./pages/Mint";
import Breed from "./pages/Breed";
import Collection from "./pages/Collection";
import MarketPlace from "./pages/MarketPlace";
import ItemDetail from "./pages/ItemDetail";
import Quest from "./pages/Quest";

// import { createAppKit } from '@reown/appkit/react'
// import { EthersAdapter } from '@reown/appkit-adapter-ethers'
// import { sepolia } from '@reown/appkit/networks'

import { createWeb3Modal, defaultConfig } from '@web3modal/ethers/react'

const projectId = process.env.REACT_APP_PROJECT_ID;


//const networks = [sepolia];

const testnet = {
  chainId: 11155111,
  name: 'Sepolia',
  currency: 'ETH',
  explorerUrl: 'https://sepolia.etherscan.io',
  rpcUrl: 'https://ethereum-sepolia-rpc.publicnode.com'
}

const metadata = {
  name: "Crypto Dragon",
  description:
    "Crypto Dragon is a contract developed using the Dragon Village collection developed by Hibro on the blockchain.",
  url: "https://github.com/bchsol/CryptoDragon",
};

//const ethersAdapter = new EthersAdapter();

const ethersConfig = defaultConfig({
  metadata,

})
createWeb3Modal({
  ethersConfig,
  chains:[testnet],
  projectId,
  enableAnalytics:true,
});

function App() {
  return (
    <>
      <Navbar />
      <Routes>
        <Route path="/" element={<Mint />} />
        <Route path="/breed" element={<Breed />} />
        <Route path="/collection" element={<Collection />} />
        <Route path="/market" element={<MarketPlace />} />
        <Route path="/item/:id" element={<ItemDetail />} />
        <Route path="/quest" element={<Quest />} />
      </Routes>
    </>
  );
}

export default App;
