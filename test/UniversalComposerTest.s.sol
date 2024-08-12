// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "forge-std/StdCheats.sol";
import "../src/UniversalComposer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MockVault {
    constructor() {}

    function deposit(uint256 assets, address receiver) public payable {}
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
    address dapp = address(0xBb287E6017d3DEb0e2E65061e8684eab21060123);

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
        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));
        token.mint(address(composer), amountLD);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](2);

        ops[0] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                address(dapp),
                uint256(99)
            )
        );
        ops[1] = UniversalComposer.Operation(
            dapp,
            0,
            abi.encodeWithSelector(
                MockVault.deposit.selector,
                uint256(99),
                address(msg.sender)
            )
        );

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
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

    function testLzComposeApproveExceedAmount() public {
        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 98;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));
        token.mint(address(composer), amountLD);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](2);

        ops[0] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                address(dapp),
                uint256(99)
            )
        );
        ops[1] = UniversalComposer.Operation(
            dapp,
            0,
            abi.encodeWithSelector(
                MockVault.deposit.selector,
                uint256(99),
                address(msg.sender)
            )
        );

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
        );

        bytes memory extraData = "";

        vm.prank(address(endpoint));
        vm.expectRevert("amount exceed received");
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            _composeMessage,
            address(endpoint),
            extraData
        );
    }

    function testLzComposeTransfer() public {
        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));
        token.mint(address(composer), 99);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](1);

        ops[0] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(msg.sender),
                uint256(99)
            )
        );

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
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

    function testLzComposeTransferExceedAmount() public {
        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));
        token.mint(address(composer), 99);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](1);

        ops[0] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(msg.sender),
                uint256(100)
            )
        );

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
        );

        bytes memory extraData = "";

        vm.prank(address(endpoint));
        vm.expectRevert("amount exceed received");
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            _composeMessage,
            address(endpoint),
            extraData
        );
    }

    function testLzComposeApproveTransfer() public {
        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));
        token.mint(address(composer), 99);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](2);

        ops[0] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                address(dapp),
                uint256(50)
            )
        );
        ops[1] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(msg.sender),
                uint256(49)
            )
        );

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
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

    function testLzComposeApproveTransferExceedAmount() public {
        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));
        token.mint(address(composer), 99);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](2);

        ops[0] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                address(dapp),
                uint256(50)
            )
        );
        ops[1] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(msg.sender),
                uint256(50)
            )
        );

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
        );

        bytes memory extraData = "";

        vm.prank(address(endpoint));
        vm.expectRevert("amount exceed received");
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            _composeMessage,
            address(endpoint),
            extraData
        );
    }

    function testLzComposeTransferFromNotAllowed() public {
        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));
        token.mint(address(composer), 99);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](1);

        ops[0] = UniversalComposer.Operation(
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                address(composer),
                address(msg.sender),
                uint256(99)
            )
        );

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
        );

        bytes memory extraData = "";

        vm.prank(address(endpoint));
        vm.expectRevert("method not allowed");
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            _composeMessage,
            address(endpoint),
            extraData
        );
    }

    function testLzComposeTransferNativeExceedAmount() public {
        stargateOApp = new MockStargateOApp(address(0));
        composer = new UniversalComposer(
            address(endpoint),
            address(stargateOApp)
        );

        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));

        vm.deal(address(composer), amountLD);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](2);

        ops[0] = UniversalComposer.Operation(address(msg.sender), 50, "");
        ops[1] = UniversalComposer.Operation(address(msg.sender), 50, "");

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
        );

        bytes memory extraData = "";

        vm.prank(address(endpoint));
        vm.expectRevert("amount exceed received");
        composer.lzCompose(
            address(stargateOApp),
            bytes32(0),
            _composeMessage,
            address(endpoint),
            extraData
        );
    }

    function testLzComposeTransferNative() public {
        stargateOApp = new MockStargateOApp(address(0));
        composer = new UniversalComposer(
            address(endpoint),
            address(stargateOApp)
        );

        uint64 nonce = 2752;
        uint32 srcEid = 30110;
        uint256 amountLD = 99;
        bytes32 composeFrom = addressToBytes32(address(msg.sender));

        vm.deal(address(composer), amountLD);

        console.log("msg.sender", msg.sender);

        UniversalComposer.Operation[]
            memory ops = new UniversalComposer.Operation[](2);

        ops[0] = UniversalComposer.Operation(address(msg.sender), 50, "");
        ops[1] = UniversalComposer.Operation(address(msg.sender), 49, "");

        bytes memory message = composer.encodeOperation(ops);

        bytes memory packedMessage = abi.encodePacked(composeFrom, message);

        bytes memory _composeMessage = OFTComposeMsgCodec.encode(
            nonce,
            srcEid,
            amountLD,
            packedMessage
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
            address(token),
            0,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                address(dapp),
                uint256(99)
            )
        );
        ops[1] = UniversalComposer.Operation(
            dapp,
            0,
            abi.encodeWithSelector(
                MockVault.deposit.selector,
                uint256(99),
                address(msg.sender)
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
        composer.withdraw(address(this), 1 ether);
        assertEq(address(this).balance, initialBalance);
    }

    function testWithdrawToken() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        token.mint(address(composer), tokenAmount);
        uint256 initialBalance = token.balanceOf(address(this));
        uint256 composerInitialBalance = token.balanceOf(address(composer));
        console.log("composerInitialBalance", composerInitialBalance);
        assertEq(token.balanceOf(address(composer)), tokenAmount);
        composer.withdrawToken(address(this), address(token), tokenAmount);
        assertEq(
            token.balanceOf(address(composer)),
            composerInitialBalance - tokenAmount
        );
        assertEq(token.balanceOf(address(this)), initialBalance + tokenAmount);
    }

    receive() external payable {}

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
