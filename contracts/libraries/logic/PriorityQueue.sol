// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

struct Heap {
    uint256[] heapList;
    uint256 currentSize;
}

library PriorityQueue {
    using SafeMath for uint256;

    /**
     * @dev Returns the top element of the heap.
     * @return The smallest element in the priority queue.
     */
    function getMin(Heap storage heap)
        internal
        view
        returns (uint256, uint256)
    {
        return _splitElement(heap.heapList[1]);
    }

    /**
     * @dev Inserts an element into the priority queue.
     * @param _tokenId Token id.
     * @param _timestamp Timestamp.
     */
    function insert(
        Heap storage heap,
        uint256 _tokenId,
        uint256 _timestamp
    ) internal {
        uint256 element = (_tokenId << 128) | _timestamp;
        heap.heapList.push(element);
        heap.currentSize = heap.currentSize.add(1);
        _percUp(heap, heap.currentSize);
    }

    /**
     * @dev Deletes the top element of the heap and shifts everything up.
     * @return The smallest element in the priorty queue.
     */
    function delMin(Heap storage heap) internal returns (uint256, uint256) {
        uint256 retVal = heap.heapList[1];
        heap.heapList[1] = heap.heapList[heap.currentSize];
        delete heap.heapList[heap.currentSize];
        heap.currentSize = heap.currentSize.sub(1);
        _percDown(heap, 1);
        //heap.heapList.length = heap.heapList.length.sub(1);
        return _splitElement(retVal);
    }

    /**
     * @dev Bubbles the element at some index up.
     */
    function _percUp(Heap storage heap, uint256 _index) internal {
        uint256 index = _index;
        uint256 j = index;
        uint256 newVal = heap.heapList[index];
        while (newVal < heap.heapList[index.div(2)]) {
            heap.heapList[index] = heap.heapList[index.div(2)];
            index = index.div(2);
        }
        if (index != j) heap.heapList[index] = newVal;
    }

    /**
     * @dev Determines the minimum child of a given node in the tree.
     * @param _index Index of the node in the tree.
     * @return The smallest child node.
     */
    function _minChild(Heap storage heap, uint256 _index)
        internal
        view
        returns (uint256)
    {
        if (_index.mul(2).add(1) > heap.currentSize) {
            return _index.mul(2);
        } else {
            if (
                heap.heapList[_index.mul(2)] <
                heap.heapList[_index.mul(2).add(1)]
            ) {
                return _index.mul(2);
            } else {
                return _index.mul(2).add(1);
            }
        }
    }

    /**
     * @dev Bubbles the element at some index down.
     */
    function _percDown(Heap storage heap, uint256 _index) internal {
        uint256 index = _index;
        uint256 j = index;
        uint256 newVal = heap.heapList[index];
        uint256 mc = _minChild(heap, index);
        while (mc <= heap.currentSize && newVal > heap.heapList[mc]) {
            heap.heapList[index] = heap.heapList[mc];
            index = mc;
            mc = _minChild(heap, index);
        }
        if (index != j) heap.heapList[index] = newVal;
    }

    /**
     * @dev Split an element into its priority and value.
     * @param _element Element to decode.
     * @return A tuple containing the token id and timestamp.
     */
    function _splitElement(uint256 _element)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 tokenId = _element >> 128;
        uint256 timestamp = uint256(uint128(_element));
        return (tokenId, timestamp);
    }
}
