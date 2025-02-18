// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import {IERC1155} from "./utils/ERC1155Interface.sol";
import {ERC1155Recipient, NonERC1155Recipient} from "./ERC1155-sol.t.sol";
import {console} from "forge-std/console.sol";

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();
    IERC1155 token;
    ERC1155Recipient holder1;
    ERC1155Recipient holder2;
    NonERC1155Recipient holder3;

    function setUp() public {
        token = IERC1155(yulDeployer.deployContract("ERC1155"));
        holder1 = new ERC1155Recipient();
        holder2 = new ERC1155Recipient();
        holder3 = new NonERC1155Recipient();
    }
    modifier mintCollections() {
        vm.startPrank(address(yulDeployer));
        token.mint(address(holder1), 1001, 1000);
        token.mint(address(holder1), 2001, 1000);
        vm.stopPrank();
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
    function testTransferFromToERC1155Recipient() public mintCollections {
        vm.prank(address(holder1));
        bytes memory data = abi.encode(2);
        token.safeTransferFrom(address(holder1), address(holder2), 1001, 500, data);
        assertEq(token.balanceOf(address(holder1), 1001), 500);
        assertEq(token.balanceOf(address(holder2), 1001), 500);
    }
    function testTransferFromRevertsIfNotERC1155Recipient() public mintCollections {
        vm.prank(address(holder1));
        bytes memory data = abi.encode(2);
        vm.expectRevert();
        token.safeTransferFrom(address(holder1), address(holder3), 1001, 500, data);
    }
    function testTransferFromToEOA() public mintCollections {
        vm.prank(address(holder1));
        bytes memory data = abi.encode(2);
        token.safeTransferFrom(address(holder1), address(4), 1001, 500, data);
        assertEq(token.balanceOf(address(holder1), 1001), 500);
        assertEq(token.balanceOf(address(4), 1001), 500);
    }
    function testSetApprovalForAll() public {
        assertEq(token.isApprovedForAll(address(holder1), address(holder2)), false);
        vm.prank(address(holder1));
        token.setApprovalForAll(address(holder2), true);
        assertEq(token.isApprovedForAll(address(holder1), address(holder2)), true);
        vm.prank(address(holder1));
        token.setApprovalForAll(address(holder2), false);
        assertEq(token.isApprovedForAll(address(holder1), address(holder2)), false);
    }
    function testTransferFromIfApprovedForAll() public mintCollections {
        vm.prank(address(holder1));
        bytes memory data = abi.encode(2);
        token.setApprovalForAll(address(holder2), true);
        vm.prank(address(holder2));
        token.safeTransferFrom(address(holder1), address(holder2), 1001, 500, data);
        assertEq(token.balanceOf(address(holder1), 1001), 500);
        assertEq(token.balanceOf(address(holder2), 1001), 500);
    }
    function testTransferFromRevertsIfNotApprovedForAll() public mintCollections {
        vm.prank(address(holder2));
        bytes memory data = abi.encode(2);
        vm.expectRevert();
        token.safeTransferFrom(address(holder1), address(holder2), 1001, 500, data);
    }
    function testBatchTransferFrom() public mintCollections {
        bytes memory data = abi.encode(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1001;
        ids[1] = 2001;
        amounts[0] = 500;
        amounts[1] = 500;
        vm.prank(address(holder1));
        token.safeBatchTransferFrom(address(holder1), address(holder2), ids, amounts, data);
        assertEq(token.balanceOf(address(holder1), 1001), 500);
        assertEq(token.balanceOf(address(holder1), 2001), 500);
        assertEq(token.balanceOf(address(holder2), 1001), 500);
        assertEq(token.balanceOf(address(holder2), 2001), 500);
    }
    function testBatchTransferFromRevertsIfNotApprovedForAll() public mintCollections {
        bytes memory data = abi.encode(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1001;
        ids[1] = 2001;
        amounts[0] = 500;
        amounts[1] = 500;
        vm.prank(address(holder2));
        vm.expectRevert();
        token.safeBatchTransferFrom(address(holder1), address(holder2), ids, amounts, data);
    }
    function testBatchTransferFromIfApprovedForAll() public mintCollections {
        bytes memory data = abi.encode(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1001;
        ids[1] = 2001;
        amounts[0] = 500;
        amounts[1] = 500;
        vm.prank(address(holder1));
        token.setApprovalForAll(address(holder2), true);
        vm.prank(address(holder2));
        token.safeBatchTransferFrom(address(holder1), address(holder2), ids, amounts, data);
        assertEq(token.balanceOf(address(holder1), 1001), 500);
        assertEq(token.balanceOf(address(holder1), 2001), 500);
        assertEq(token.balanceOf(address(holder2), 1001), 500);
        assertEq(token.balanceOf(address(holder2), 2001), 500);
    }
    function testBatchTransferFromRevertsIfNotERC1155Recipient() public mintCollections {
        bytes memory data = abi.encode(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1001;
        ids[1] = 2001;
        amounts[0] = 500;
        amounts[1] = 500;
        vm.prank(address(holder1));
        vm.expectRevert();
        token.safeBatchTransferFrom(address(holder1), address(holder3), ids, amounts, data);
    }
    function testBatchTransferFromToEOA() public mintCollections {
        bytes memory data = abi.encode(2);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1001;
        ids[1] = 2001;
        amounts[0] = 500;
        amounts[1] = 500;
        vm.prank(address(holder1));
        token.safeBatchTransferFrom(address(holder1), address(4), ids, amounts, data);
        assertEq(token.balanceOf(address(holder1), 1001), 500);
        assertEq(token.balanceOf(address(holder1), 2001), 500);
        assertEq(token.balanceOf(address(4), 1001), 500);
        assertEq(token.balanceOf(address(4), 2001), 500);
    }
}
