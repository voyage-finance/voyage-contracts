// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../component/Voyager.sol';
import '../component/infra/AddressResolver.sol';
import '../component/shared/storage/LiquidityManagerStorage.sol';
import '../component/shared/escrow/LiquidityDepositEscrow.sol';
import '../libraries/types/DataTypes.sol';

abstract contract IVoyagerComponent {
    Voyager public voyager;

    modifier requireNotPaused() {
        _whenNotPaused();
        _;
    }

    function liquidityManagerStorageAddress() internal view returns (address) {
        return
            AddressResolver(voyager.getAddressResolverAddress())
                .getLiquidityManagerStorage();
    }

    function _whenNotPaused() internal view {
        require(!paused(), Errors.LP_IS_PAUSED);
    }

    function paused() internal view returns (bool) {
        address storageAddress = liquidityManagerStorageAddress();
        return LiquidityManagerStorage(storageAddress).paused();
    }

    function getDepositAndDebt(address _reserve)
        public
        view
        returns (DataTypes.DepositAndDebt memory)
    {
        address storageAddress = liquidityManagerStorageAddress();
        return
            LiquidityManagerStorage(storageAddress).getDepositAndDebt(_reserve);
    }

    function escrow() internal view virtual returns (LiquidityDepositEscrow);
}
