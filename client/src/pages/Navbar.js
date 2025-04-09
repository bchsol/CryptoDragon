import React from "react";
import { useState } from "react";
import { useWeb3ModalAccount,useWeb3Modal } from "@web3modal/ethers/react";
import {
  CollapsedMenu,
  NavLink,
  NavLinks,
  NavbarContainer,
  NavbarButton,
  NavbarToggle,
  MobileMenu,
} from "../Style/NavbarStyles.js";

function Navbar() {
  const { address, isConnected } = useWeb3ModalAccount();
  const { open } = useWeb3Modal();
  const truncateAccount = address
    ? address.substring(0, 6) + "..." + address.substring(address.length - 4)
    : null;

  const [isOpen, setIsOpen] = useState(false);

  return (
    <NavbarContainer>
      <NavbarToggle onClick={() => setIsOpen(!isOpen)}>☰</NavbarToggle>

      <NavLinks >
        <CollapsedMenu>
          <NavLink to="/">Mint</NavLink>
          <NavLink to="/breed">Breed</NavLink>
          <NavLink to="/collection">Collection</NavLink>
          <NavLink to="/market">Market</NavLink>
          <NavLink to="/quest">Quest</NavLink>
        </CollapsedMenu>
      </NavLinks>

      <NavbarButton onClick={() => open()}>
        {!isConnected ? "Connect Wallet" : truncateAccount}
      </NavbarButton>

      {isOpen && (
        <MobileMenu>
          <NavLink to="/">Mint</NavLink>
          <NavLink to="/breed">Breed</NavLink>
          <NavLink to="/collection">Collection</NavLink>
          <NavLink to="/market">Market</NavLink>
          <NavLink to="/quest">Quest</NavLink>
        </MobileMenu>
      )}
    </NavbarContainer>
  );
}

export default Navbar;
