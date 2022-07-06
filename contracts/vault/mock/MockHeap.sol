pragma solidity ^0.8.9;

import {PriorityQueue, Heap} from "../libraries/PriorityQueue.sol";

contract MockHeap {
    using PriorityQueue for Heap;

    Heap heap;

    function insert(uint256 _tokenId, uint256 _timestamp) external {
        heap.insert(_tokenId, _timestamp);
    }

    function delMin() external returns (uint256, uint256) {
        return heap.delMin();
    }

    function del(uint256 _tokenId, uint256 _timestamp) external {
        heap.del(_tokenId, _timestamp);
    }

    function getMin() external view returns (uint256, uint256) {
        return heap.getMin();
    }

    function getSize() external view returns (uint256) {
        return heap.currentSize;
    }

    function getList() external view returns (uint256[] memory) {
        return heap.heapList;
    }
}