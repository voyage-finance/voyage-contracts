// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MockMarketPlace is Ownable, IERC721Receiver, ReentrancyGuard {
    uint256 constant PERCENT_BASE = 10000;
    IERC20 public paymentToken;
    IERC721 public cardToken;

    struct Order {
        address owner;
        uint256 cardId;
        uint256 cardPrice;
    }

    mapping(uint256 => Order) public sellOrders;
    uint256 public currentOrderId;
    uint256 public tradingFeePercent;
    address public feeAddress;

    event MakeSellOrder(
        uint256 indexed orderId,
        address indexed seller,
        uint256 indexed cardId,
        uint256 cardPrice
    );
    event BuyCard(
        uint256 indexed orderId,
        address indexed buyer,
        address indexed seller,
        uint256 cardId,
        uint256 cardPrice
    );
    event CancelSellOrder(uint256 orderId);
    event ChangeFee(uint256 newFee);
    event ChangeFeeAddress(address newAddress);

    constructor(
        IERC20 token,
        IERC721 card,
        uint256 feePercent,
        address feeAddr
    ) {
        paymentToken = token;
        cardToken = card;
        tradingFeePercent = feePercent;
        feeAddress = feeAddr;
    }

    /**
     * Place an order to sell a card.
     */
    function makeSellOrder(uint256 cardId, uint256 cardPrice) external {
        cardToken.safeTransferFrom(
            msg.sender,
            address(this),
            cardId,
            abi.encodePacked(cardPrice)
        );
    }

    /**
     * Cancel sale
     */
    function cancelSellOrder(uint256 orderId) external {
        Order storage od = sellOrders[orderId];
        require(od.owner == msg.sender, "Not owner");
        // Send back the card
        cardToken.safeTransferFrom(address(this), msg.sender, od.cardId);
        delete sellOrders[orderId];
        emit CancelSellOrder(orderId);
    }

    /**
     * Buy card
     */
    function buyCard(uint256 orderId) external payable nonReentrant {
        Order storage od = sellOrders[orderId];
        address payable seller = payable(od.owner);
        uint256 cardId = od.cardId;
        require(seller != address(0), "Invalid order ");
        od.owner = address(0);
        // Transfer card to the msg.sender
        cardToken.safeTransferFrom(address(this), msg.sender, cardId);
        // Transfer token
        uint256 price = od.cardPrice;
        uint256 receiveAmount = price;
        if (address(paymentToken) == address(0x0)) {
            // Native coinn
            require(msg.value == price, "INVALID VALUE");
        }
        if (tradingFeePercent > 0) {
            uint256 fee = (price * tradingFeePercent) / PERCENT_BASE;
            receiveAmount = price - fee;
            paymentToken.transferFrom(msg.sender, feeAddress, fee);
            transferFee(payable(feeAddress), fee);
        }
        paymentToken.transferFrom(msg.sender, seller, receiveAmount);
        transferFee(seller, receiveAmount);
        emit BuyCard(orderId, msg.sender, seller, cardId, price);
        delete sellOrders[orderId];
    }

    /**
     * Send card to this contract to sell.
     * Data is the price.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(cardToken), "Accept CRABADA only");
        uint256 cardPrice = abi.decode(data, (uint256));
        setSellCardInfo(from, tokenId, cardPrice);
        return
            bytes4(
                keccak256("onERC721Received(address, address, uint256, bytes)")
            );
    }

    /**
     * Place a sell order.
     * This function is called when this smart contract receives a card from the card smart contract
     */
    function setSellCardInfo(
        address seller,
        uint256 cardId,
        uint256 cardPrice
    ) internal {
        Order memory od = Order(seller, cardId, cardPrice);
        sellOrders[currentOrderId] = od;
        emit MakeSellOrder(currentOrderId, seller, cardId, cardPrice);
        currentOrderId++;
    }

    /**
     * Change fee
     */
    function setFee(uint256 newFee) external onlyOwner {
        tradingFeePercent = newFee;
        emit ChangeFee(newFee);
    }

    /**
     * Change fee address
     */
    function setFeeAddress(address newAddress) external onlyOwner {
        feeAddress = newAddress;
        emit ChangeFeeAddress(newAddress);
    }

    function transferFee(address payable to, uint256 amount) internal {
        if (address(paymentToken) == address(0x0)) {
            // Native coin
            to.transfer(amount);
        } else {
            paymentToken.transferFrom(msg.sender, to, amount);
        }
    }
}
