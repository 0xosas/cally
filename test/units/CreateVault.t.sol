// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../shared/Fixture.t.sol";
import "src/Cally.sol";

contract TestCreateVault is Test, Fixture {
    event NewVault(uint256 indexed vaultId, address indexed from, address indexed token);

    function setUp() public {
        bayc.mint(address(this), 1);
        bayc.mint(address(this), 2);
        bayc.mint(address(this), 100);
        bayc.setApprovalForAll(address(c), true);
    }

    function testItEmitsNewVaultEvent() public {
        // act
        vm.expectEmit(true, true, true, false);
        emit NewVault(3, address(this), address(bayc));
        c.createVault(1, address(bayc), 2, 1, 0, Cally.TokenType.ERC721);
    }

    function testItSendsERC721ForCollateral() public {
        // act
        c.createVault(1, address(bayc), 2, 1, 0, Cally.TokenType.ERC721);

        // assert
        assertEq(bayc.balanceOf(address(c)), 1, "Should have sent BAYC to Cally");
        assertEq(bayc.ownerOf(1), address(c), "Should have sent BAYC to Cally");
    }

    function testItSendsERC20ForCollateral() public {
        // arrange
        uint256 amount = 1337;
        link.mint(address(this), amount);
        link.approve(address(c), amount);
        uint256 balanceBefore = link.balanceOf(address(this));

        // act
        c.createVault(amount, address(link), 2, 1, 0, Cally.TokenType.ERC20);
        uint256 change = balanceBefore - link.balanceOf(address(this));

        // assert
        assertEq(link.balanceOf(address(c)), amount, "Should have sent LINK to Cally");
        assertEq(change, amount, "Should have sent LINK from account");
    }

    function testItMintsVaultERC721ToCreator() public {
        // act
        uint256 vaultId = c.createVault(1, address(bayc), 2, 1, 0, Cally.TokenType.ERC721);

        // assert
        assertEq(c.ownerOf(vaultId), address(this), "Should have minted vault token");
    }

    function testItCreatesVaultDetails() public {
        // arrange
        uint256 tokenId = 1;
        address token = address(bayc);
        uint8 premium = 2;
        uint8 durationDays = 3;
        uint8 dutchAuctionStartingStrike = 3;
        Cally.TokenType tokenType = Cally.TokenType.ERC721;

        // act
        uint256 vaultId = c.createVault(tokenId, token, premium, durationDays, dutchAuctionStartingStrike, tokenType);

        // assert
        Cally.Vault memory vault = c.vaults(vaultId);
        assertEq(vault.tokenIdOrAmount, tokenId, "Should have set tokenId");
        assertEq(vault.token, token, "Should have set token");
        assertEq(vault.premium, premium, "Should have set premium");
        assertEq(vault.durationDays, durationDays, "Should have set durationDays");
        assertEq(vault.dutchAuctionStartingStrike, dutchAuctionStartingStrike, "Should have set starting strike");
        assertEq(uint8(vault.tokenType), uint8(tokenType), "Should have set tokenType");
    }

    function testItIncrementsVaultId() public {
        // act
        uint256 vaultId = c.createVault(1, address(bayc), 2, 1, 0, Cally.TokenType.ERC721);

        // assert
        uint256 vaultIndex = c.vaultIndex();
        assertEq(vaultIndex, 3, "Should have incremented vaultIndex by 2");
        assertEq(vaultId, 3, "Should have returned vaultId");
    }

    function testItIncrementsVaultIdMultipleTimes() public {
        // act
        uint256 vaultId1 = c.createVault(1, address(bayc), 2, 1, 0, Cally.TokenType.ERC721);
        uint256 vaultId2 = c.createVault(2, address(bayc), 2, 1, 0, Cally.TokenType.ERC721);
        uint256 vaultId3 = c.createVault(100, address(bayc), 2, 1, 0, Cally.TokenType.ERC721);

        // assert
        uint256 vaultIndex = c.vaultIndex();
        assertEq(vaultIndex, 7, "Should have incremented vaultIndex by 2");
        assertEq(vaultId1, 3, "Should have incremented vaultId by 2");
        assertEq(vaultId2, 5, "Should have incremented vaultId by 2");
        assertEq(vaultId3, 7, "Should have incremented vaultId by 2");
    }

    function testItCannotCreateVaultWithInvalidPremium() public {
        // act
        vm.expectRevert("Invalid premium index");
        c.createVault(1, address(bayc), 150, 1, 0, Cally.TokenType.ERC721);
    }

    function testItCannotCreateVaultWithInvalidStrike() public {
        // act
        vm.expectRevert("Invalid strike index");
        c.createVault(1, address(bayc), 1, 12, 150, Cally.TokenType.ERC721);
    }

    function testItCannotCreateVaultWithInvalidDurationDays() public {
        // act
        vm.expectRevert("Invalid durationDays");
        c.createVault(1, address(bayc), 1, 0, 1, Cally.TokenType.ERC721);
    }

    function testItCreatesVault(
        uint8 premium,
        uint8 durationDays,
        uint8 dutchAuctionStartingStrike
    ) public {
        vm.assume(premium < 17);
        vm.assume(durationDays > 0);
        vm.assume(dutchAuctionStartingStrike < 19);

        // act
        uint256 vaultId = c.createVault(
            1,
            address(bayc),
            premium,
            durationDays,
            dutchAuctionStartingStrike,
            Cally.TokenType.ERC721
        );

        // assert
        Cally.Vault memory vault = c.vaults(vaultId);
        assertEq(vault.tokenIdOrAmount, 1, "Should have set tokenId");
        assertEq(vault.token, address(bayc), "Should have set token");
        assertEq(vault.premium, premium, "Should have set premium");
        assertEq(vault.durationDays, durationDays, "Should have set durationDays");
        assertEq(vault.dutchAuctionStartingStrike, dutchAuctionStartingStrike, "Should have set starting strike");
    }
}
