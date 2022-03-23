// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface ICryprosaurus is IERC721 {

    /**** the key parameter for Cryprosaurus ****/
    /*
    * the context of Cryprosaurus
    *   the kind of dinosaur:    0~50;
    *   the skin of body:        0~3;
    *   the skin of eye:         0~15;
    *   the scale of dinosaur:   1~100
    */
    struct dinosaurContext {
        uint kind;
        uint bodySkin;
        uint eyeSkin;
        uint scale;
    }

    struct mintInput {
        dinosaurContext context;
        address to;
    }

    event Mint(address to, uint tokenId, dinosaurContext context);

    function mint(mintInput calldata input) external;
    function getProperty(address user) external view returns (uint256[] memory);
}