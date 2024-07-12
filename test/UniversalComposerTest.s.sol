// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/UniversalComposer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MockEndpoint {
    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable {
        UniversalComposer(payable(_to)).lzCompose{value: msg.value}(
            _from,
            _guid,
            _message,
            msg.sender,
            _extraData
        );
    }
}

contract MockStargateOApp {
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }
}

contract UniversalComposerTest is Test {
    UniversalComposer public composer;
    MockERC20 public token;
    MockEndpoint public endpoint;
    MockStargateOApp public stargateOApp;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        token = new MockERC20();
        endpoint = new MockEndpoint();
        stargateOApp = new MockStargateOApp(address(token));
        composer = new UniversalComposer(
            address(endpoint),
            address(stargateOApp)
        );
    }

    function testConstructor() public view {
        assertEq(composer.endpoint(), address(endpoint));
        assertEq(composer.stargateOApp(), address(stargateOApp));
        assertEq(composer.owner(), owner);
    }

    function testLzCompose() public {
        uint64 nonce = 1;
        uint32 srcEid = 1;
        uint256 amountLD = 10;

        bytes memory _composeMessage = fromHex(
            "0000000000000ac00000759e0000000000000000000000000000000000000000000000000000000000000063000000000000000000000000436f795b64e23e6ce7792af4923a68afd3967952c2132d05d31c914a87c6611c10748aeb04b58e8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b3000000000000000000000000bb287e6017d3deb0e2e65061e8684eab210601230000000000000000000000000000000000000000000000000000000000000063bb287e6017d3deb0e2e65061e8684eab21060123000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000446e553f650000000000000000000000000000000000000000000000000000000000000063000000000000000000000000be988fc9f6f8ad1ebb3a58b6c25bd6be9d1f56fe"
        );

        bytes memory extraData = "";

        vm.prank(address(endpoint));
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            _composeMessage,
            address(endpoint),
            extraData
        );
    }

    function testLzComposeRevertOnInvalidSender() public {
        uint64 nonce = 1;
        uint32 srcEid = 1;
        uint256 amountLD = 100 * 10 ** 18;
        bytes memory composeMsg = abi.encodePacked("testCompose");

        bytes memory message = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            composeMsg
        );

        vm.expectRevert("Can only be called by LayerZero endpoint.");
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            message,
            address(0),
            ""
        );
    }

    function testLzComposeRevertOnInvalidFrom() public {
        uint64 nonce = 1;
        uint32 srcEid = 1;
        uint256 amountLD = 100 * 10 ** 18;
        bytes memory composeMsg = abi.encodePacked("testCompose");

        bytes memory message = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            composeMsg
        );

        vm.prank(address(endpoint));
        vm.expectRevert("_from should be the StargateOApp.");
        composer.lzCompose(address(0), bytes32(0), message, address(0), "");
    }

    function testEncodeOperation() public view {
        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](2);
        ops[0] = UniversalComposer.Operation(
            address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F),
            100,
            fromHex(
                "095ea7b3000000000000000000000000bb287e6017d3deb0e2e65061e8684eab210601230000000000000000000000000000000000000000000000000000000000000063"
            )
        );
        ops[1] = UniversalComposer.Operation(
            address(0xBb287E6017d3DEb0e2E65061e8684eab21060123),
            200,
            fromHex(
                "6e553f650000000000000000000000000000000000000000000000000000000000000063000000000000000000000000be988fc9f6f8ad1ebb3a58b6c25bd6be9d1f56fe"
            )
        );

        bytes memory encoded = composer.encodeOperation(ops);
        console.logBytes(encoded);
        assertEq(encoded.length, 2 * (20 + 32 + 32 + 68)); // 2 operations * (address + value + length + data)
    }

    function testPause() public {
        composer.pause();
        assertTrue(composer.paused());
    }

    function testUnpause() public {
        composer.pause();
        composer.unpause();
        assertFalse(composer.paused());
    }

    function testLzComposeWhenPaused() public {
        composer.pause();
        uint64 nonce = 1;
        uint32 srcEid = 1;
        uint256 amountLD = 100 * 10 ** 18;
        bytes memory composeMsg = abi.encodePacked("testCompose");

        bytes memory message = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            composeMsg
        );

        vm.prank(address(endpoint));
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            message,
            address(0),
            ""
        );
    }

    function testWithdraw() public {
        uint256 initialBalance = address(this).balance;
        payable(address(composer)).transfer(1 ether);
        composer.withdraw(address(this));
        assertEq(address(this).balance, initialBalance);
    }

    function testWithdrawToken() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        token.mint(address(composer), tokenAmount);
        uint256 initialBalance = token.balanceOf(address(this));
        uint256 composerInitialBalance = token.balanceOf(address(composer));
        console.log("composerInitialBalance", composerInitialBalance);
        assertEq(token.balanceOf(address(composer)), tokenAmount);
        composer.withdrawToken(address(this), address(token));
        assertEq(
            token.balanceOf(address(composer)),
            composerInitialBalance - tokenAmount
        );
        assertEq(token.balanceOf(address(this)), initialBalance + tokenAmount);
    }

    receive() external payable {}

    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        revert("fail to convert from hex char");
    }

    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0); // length must be even
        bytes memory r = new bytes(ss.length / 2);
        for (uint i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(
                fromHexChar(uint8(ss[2 * i])) *
                    16 +
                    fromHexChar(uint8(ss[2 * i + 1]))
            );
        }
        return r;
    }
}
