# After running slither

command

```bash
slither src --ignore-compile --solc-remaps @openzeppelin/contracts=lib/openzeppelin-contracts/contracts --exclude-dependencies
```

## yellow

[✅] - TSwapPool.revertIfZero(uint256) -dangerous strict equality

```
TSwapPool.revertIfZero(uint256) (src/TSwapPool.sol#57-62) uses a dangerous strict equality:
        - amount == 0 (src/TSwapPool.sol#58)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
```

## green

[✅] reentrancy Reentrancy in <SwapPool.\_swap(IERC20,uint256,IERC20,uint256)

```
Reentrancy in <SwapPool._swap(IERC20,uint256,IERC20,uint256) (src/TSwapPool.sol#323-337):
        External calls:
        - outputToken.safeTransfer(msg.sender,1_000_000_000_000_000_000) (src/TSwapPool.sol#331)
        Event emitted after the call(s):
        - Swap(msg.sender,inputToken,inputAmount,outputToken,outputAmount) (src/TSwapPool.sol#333)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
```

[✅] never used call

```

Address.functionDelegateCall(address,bytes) (lib/openzeppelin-contracts/contracts/utils/Address.sol#104-107) is never used and should be removed
Address.functionStaticCall(address,bytes) (lib/openzeppelin-contracts/contracts/utils/Address.sol#95-98) is never used and should be removed
Address.sendValue(address,uint256) (lib/openzeppelin-contracts/contracts/utils/Address.sol#41-50) is never used and should be removed
Address.verifyCallResult(bool,bytes) (lib/openzeppelin-contracts/contracts/utils/Address.sol#135-141) is never used and should be removed
Context._msgData() (lib/openzeppelin-contracts/contracts/utils/Context.sol#21-23) is never used and should be removed
SafeERC20._callOptionalReturnBool(IERC20,bytes) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#110-117) is never used and should be removed
SafeERC20.forceApprove(IERC20,address,uint256) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#76-83) is never used and should be removed
SafeERC20.safeDecreaseAllowance(IERC20,address,uint256) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#61-69) is never used and should be removed
SafeERC20.safeIncreaseAllowance(IERC20,address,uint256) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#52-55) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
```

[✅] low level call (what is that?)

```

Low level call in SafeERC20._callOptionalReturnBool(IERC20,bytes) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#110-117):
        - (success,returndata) = address(token).call(data) (lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#115)
Low level call in Address.sendValue(address,uint256) (lib/openzeppelin-contracts/contracts/utils/Address.sol#41-50):
        - (success) = recipient.call{value: amount}() (lib/openzeppelin-contracts/contracts/utils/Address.sol#46)
Low level call in Address.functionCallWithValue(address,bytes,uint256) (lib/openzeppelin-contracts/contracts/utils/Address.sol#83-89):
        - (success,returndata) = target.call{value: value}(data) (lib/openzeppelin-contracts/contracts/utils/Address.sol#87)
Low level call in Address.functionStaticCall(address,bytes) (lib/openzeppelin-contracts/contracts/utils/Address.sol#95-98):
        - (success,returndata) = target.staticcall(data) (lib/openzeppelin-contracts/contracts/utils/Address.sol#96)
Low level call in Address.functionDelegateCall(address,bytes) (lib/openzeppelin-contracts/contracts/utils/Address.sol#104-107):
        - (success,returndata) = target.delegatecall(data) (lib/openzeppelin-contracts/contracts/utils/Address.sol#105)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls
```
