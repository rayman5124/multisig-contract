// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import "./ERC20.sol";

contract TestToken is ERC20{
    constructor() ERC20(1e5 ether, "TestToken", 18, "TTK") {}
}
