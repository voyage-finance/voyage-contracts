import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Lib Heap', function () {
  it('Delete minimal on heap should return correct value', async function () {
    const MockHeap = await ethers.getContractFactory('MockHeap');
    const mockHeap = await MockHeap.deploy();

    // insert three
    await mockHeap.insert(0, 3);
    await mockHeap.insert(0, 4);
    await mockHeap.insert(0, 2);

    const minNode = await mockHeap.getMin();
    console.log(minNode.toString());

    await mockHeap.delMin();
    const minNode2 = await mockHeap.getMin();
    console.log(minNode2.toString());

    await mockHeap.delMin();
    const minNode3 = await mockHeap.getMin();
    console.log(minNode3.toString());

    await mockHeap.delMin();
    const sizeAfterDel = await mockHeap.getSize();
    console.log(sizeAfterDel.toString());
  });

  it('Delete by value on heap should return correct value', async function () {
    const MockHeap = await ethers.getContractFactory('MockHeap');
    const mockHeap = await MockHeap.deploy();

    // insert three
    await mockHeap.insert(0, 4);
    const list0 = await mockHeap.getList();
    console.log('list 0: ', list0.toString());

    await mockHeap.insert(0, 3);
    const list1 = await mockHeap.getList();
    console.log('list 1: ', list1.toString());

    await mockHeap.insert(0, 2);
    const list2 = await mockHeap.getList();
    console.log('list 2: ', list2.toString());

    await mockHeap.del(0, 2);
    const list3 = await mockHeap.getList();
    console.log('list 3: ', list3.toString());
    const minNode = await mockHeap.getMin();
    console.log(minNode.toString());

    await mockHeap.insert(0, 1);
    const minNode2 = await mockHeap.getMin();
    console.log(minNode2.toString());
    const list4 = await mockHeap.getList();
    console.log('list 4: ', list4.toString());

    await mockHeap.del(0, 3);
    const list5 = await mockHeap.getList();
    console.log('list5: ', list5.toString());
  });
});
