// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import {IERC1155} from "./utils/ERC1155Interface.sol";
import {console} from "forge-std/console.sol";

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();
    IERC1155 token;
    address holder1 = makeAddr("holder1");
    address holder2 = makeAddr("holder2");

    function setUp() public {
        token = IERC1155(yulDeployer.deployContract("ERC1155"));
    }
    modifier mintCollections() {
        token.mint(holder1, 1001, 1);
        _;
    }
    function testOwner() public {
        assertEq(token.owner(), address(yulDeployer));
    }
    function testMint() public {
        vm.prank(address(yulDeployer));
        token.mint(address(0xBEEF), 1337, 1);
        assertEq(token.balanceOf(address(0xBEEF), 1337), 1);
    }
    function testMintRevertsIfNotOwner() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        token.mint(address(0xBEEF), 1337, 1);
    }
}
