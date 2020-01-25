const {
    BN
} = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const IEther = artifacts.require('IEther');

contract('test IEther', async () => {
    it('checking get name', async () => {
        this.iether = await IEther.new();
        expect(await this.iether.name.call()).equal('iEther');
    });
});
