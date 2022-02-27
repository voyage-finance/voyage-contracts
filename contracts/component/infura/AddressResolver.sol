// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract AddressResolver {
    address voyager;
    address liquidityManager;
    address vaultManager;
    address loanManager;

    modifier onlyVoyager() {
        require(voyager == msg.sender, 'The caller must be a voyager');
        _;
    }

    event VoyagerAddressUpdated(address indexed _voyager);

    event LiquidityManagerUpdated(address indexed _liquidityManager);

    event VaultManagerUpdated(address indexed _vaultManager);

    event LoanManagerUpdated(address indexed _loanManager);

    constructor(
        address _voyager,
        address _liquidityManager,
        address _vaultManager,
        address _loadManager
    ) public {
        voyager = _voyager;
        liquidityManager = _liquidityManager;
        vaultManager = _vaultManager;
        loanManager = _loadManager;
    }

    function getVoyagerAddress() public view returns (address) {
        return voyager;
    }

    function setVoyagerAddress(address _voyager) external onlyVoyager {
        voyager = _voyager;
        emit VoyagerAddressUpdated(_voyager);
    }

    function getLiquidityManager() public view returns (address) {
        return liquidityManager;
    }

    function setLiquidityManager(address _liquidityManager)
        external
        onlyVoyager
    {
        liquidityManager = _liquidityManager;
        emit LiquidityManagerUpdated(_liquidityManager);
    }

    function getVaultManager() public view returns (address) {
        return vaultManager;
    }

    function setVaultManager(address _vaultManager) external onlyVoyager {
        vaultManager = _vaultManager;
        emit VaultManagerUpdated(_vaultManager);
    }

    function getLoanManager() public view returns (address) {
        return loanManager;
    }

    function setLoanManager(address _loanManager) external onlyVoyager {
        loanManager = _loanManager;
        emit LoanManagerUpdated(_loanManager);
    }
}
