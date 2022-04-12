// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import "../../interfaces/IACLManager.sol";

contract ACLManager is AccessControl,IACLManager {

}