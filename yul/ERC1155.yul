object "ERC1155" {
    code {
      // Store the creator in slot zero.
      sstore(0, caller())

      datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
      return(0, datasize("Runtime"))
    }
    object "Runtime" {
      // Return the calldata
      code {
       
        // Protection against sending Ether
        require(iszero(callvalue()))
        
        // Dispatcher
        switch selector()
        
        case 0x8da5cb5b /* "owner()" */ {
            returnUint(owner())
        }
        case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
            returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
        }
        case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {
            balanceOfBatch(decodeAsUint(0), decodeAsUint(1))
        }
        case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
            setApprovalForAll(decodeAsAddress(0), decodeAsUint(1))
            returnTrue()
        }
        case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {
            returnUint(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
        }
        case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
            transferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
            returnTrue()
        }
        case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {
            batchTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
            returnTrue()
        }
        case 0x156e29f6 /* "mint(address,uint256,uint256)" */ {
            mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            returnTrue()
        }
        default {
            revert(0, 0)
        }
        /* ---------- calldata encoding functions ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
            function returnTrue() {
                returnUint(1)
            }

        /* ---------- functions ----------- */
        function mint(account, tokenId, amount) {
            require(calledByOwner())
            addToBalance(account, tokenId, amount)
            emitTransferSingle(caller(), 0, account, tokenId, amount)
        }
        function balanceOfBatch(accountsLengthPos, tokenIdsLengthPos) {
            let accountsLength := decodeLength(accountsLengthPos)
            let tokenIdsLength := decodeLength(tokenIdsLengthPos)
            require(eq(accountsLength, tokenIdsLength))
            let accountsFirstElementPos := add(0x20, accountsLengthPos)
            let tokenIdsFirstElementPos := add(0x20, tokenIdsLengthPos)
            let i := 0
            let p := 0
            for { } lt(i, accountsLength) { } {   
                mstore(p, balanceOf(decodeArrayItemAsUint(accountsFirstElementPos, i), decodeArrayItemAsUint(tokenIdsFirstElementPos, i)))  
                p := add(p, 0x20)
                i := add(i, 1)
            }
            return(0, p)
        }
        function setApprovalForAll( spender, isApproved) {
            sstore(allowanceStorageOffset(caller(), spender), isApproved)
            emitApprovalForAll(caller(), spender, isApproved)
        }
        function transferFrom(from, to, tokenId, amount, dataLengthPos){
            require(or(eq(caller(), from), isApprovedForAll(from, caller())))

            deductFromBalance(from, tokenId, amount)   
            addToBalance(to, tokenId, amount)

            emitTransferSingle(caller(), from, to, tokenId, amount)

            let size := extcodesize(to)
            if gt(size, 0) {

                let eventSelector := 0xf23a6e61
                mstore(0x00, shl(0xe0,eventSelector))     // Store function selector
                calldatacopy(0x04, 0x04, sub(calldatasize(), 4))
             
                let success := call(
                    gas(),  // Forward all gas
                    to,     // Call `to`
                    0,      // No ETH
                    0x00, // Input data pointer
                    calldatasize(), // Input size
                    0x00, // Output location
                    0x04     // Output size (expected return amount)
                )

                require(success)
                require(eq(shr(0xe0,mload(0x00)), eventSelector))
              
            } 
        }
        function batchTransferFrom(from, to,  tokenIdsLengthPos, amountsLengthPos, dataLengthPos){
            require(or(eq(caller(), from), isApprovedForAll(from, caller())))
            require(eq(decodeLength(amountsLengthPos), decodeLength(tokenIdsLengthPos)))
            let length := decodeLength(amountsLengthPos)
            let i := 0
            
            
            
            for { } lt(i, length) { } { 
                let tokenIdsFirstElementPos := getFirstElementPosition(tokenIdsLengthPos)
                let amountsFirstElementPos := getFirstElementPosition(amountsLengthPos)
                
                let tokenId := decodeArrayItemAsUint(tokenIdsFirstElementPos, i) 
                let amount := decodeArrayItemAsUint(amountsFirstElementPos, i)
               
                deductFromBalance(from, tokenId, amount)
                addToBalance(to, tokenId, amount)
                
                i := add(i, 1)
            }
            if gt(extcodesize(to), 0) {
                let eventSelector := 0xbc197c81
                mstore(0x00, shl(0xe0,eventSelector))
                calldatacopy(0x04, 0x04, sub(calldatasize(), 4))
                let success := call(
                    gas(),  // Forward all gas
                    to,     // Call `to`
                    0,      // No ETH
                    0x00, // Input data pointer
                    calldatasize(), // Input size
                    0x00, // Output location
                    0x20     // Output size (expected return amount)
                )
                require(success)
                require(eq(shr(0xe0,mload(0x00)), eventSelector))
               
            } 
            let tokenIdsOffset := 0x40
            let totalBytesLength := mul(add(0x20, mul(0x20,length)),2)
            let amountsOffset := add(0x40, div(totalBytesLength, 2))
            mstore(0x00, tokenIdsOffset)   // tokenIds offset
            mstore(0x20, amountsOffset)   // amounts offset
            calldatacopy(tokenIdsOffset, 0xa4,totalBytesLength)
            emitTransferBatch(caller(), from, to, 0x00, add(0x40,totalBytesLength))
            


            
            

        }
       
         /* -------- storage layout ---------- */
         function ownerPos() -> p { p := 0 }
         function balancePos() -> p { p := 1 }
         function allowancePos() -> p { p := 2 }
         function balanceStorageOffset(account, tokenId) -> offset {
             mstore(0, balancePos())
             mstore(0x20, account)
             let sha := keccak256(0, 0x40)
             mstore(0, sha)
             mstore(0x20, tokenId)
             offset := keccak256(0, 0x40)
         }
         function allowanceStorageOffset(account, spender) -> offset {
             mstore(0, allowancePos())
             mstore(0x20, account)
             let sha := keccak256(0, 0x40)
             mstore(0, sha)
             mstore(0x20, spender)
             offset := keccak256(0, 0x40)
         }

   /* -------- storage access ---------- */
   function owner() -> o {
    o := sload(ownerPos())
   }
   function balanceOf(account, tokenId) -> bal {
       bal := sload(balanceStorageOffset(account, tokenId))
   }
   function addToBalance(account, tokenId, amount) {
       let offset := balanceStorageOffset(account, tokenId)
       sstore(offset, safeAdd(sload(offset), amount))
   }
   function deductFromBalance(account, tokenId, amount) {
       let offset := balanceStorageOffset(account, tokenId)
       let bal := sload(offset)
       sstore(offset, safeSub(bal, amount))
   }
   function isApprovedForAll(account, spender) -> isApproved {
       isApproved := sload(allowanceStorageOffset(account, spender))
   }
 
   function decreaseAllowanceBy(account, spender, amount) {
       let offset := allowanceStorageOffset(account, spender)
       let currentAllowance := sload(offset)
       require(lte(amount, currentAllowance))
       sstore(offset, sub(currentAllowance, amount))
   }


        /* ---------- calldata decoding functions ----------- */
        function selector() -> s {
           s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
        }

        function decodeAsAddress(offset) -> v {
            v := decodeAsUint(offset)
            if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                revert(0, 0)
            }
        }
        function decodeAsUint(offset) -> v {
            let pos := add(4, mul(offset, 0x20))
            if lt(calldatasize(), add(pos, 0x20)) {
                revert(0, 0)
            }
            v := calldataload(pos)
        }
        function decodeLength(lengthPos) -> v {
            if lt(calldatasize(), add(lengthPos, 0x20)) {
                revert(0, 0)
            }
            v := calldataload(add(lengthPos, 4))
        }
        function getFirstElementPosition(lengthPos) -> v {
            v := add(0x24, lengthPos)
        }
        function decodeArrayItemAsUint(positionOfFirstElement, index) -> v {
            let pos := add(positionOfFirstElement, mul(index, 0x20))
            if lt(calldatasize(), add(pos, 0x20)) {
                revert(0, 0)
            }
            v := calldataload(pos)
        }
        
        /* -------- events ---------- */
        function emitTransferSingle(operator, from, to, tokenId, amount) {
            let signatureHash := 0xc3d58168c5c4b7b1f1dcf0749948ca480bd1d1f55d7bdfc7e7401f5a06b38be1
            mstore(0, tokenId)
            mstore(0x20, amount)
            log4(0, 0x40, signatureHash, operator, from, to)
        }
        function emitTransferBatch(operator, from, to, nonIndexedPos, nonIndexedLength) {
            let signatureHash := 0x4a39dc06d4c0dbc64b70d06ec49141a0adf6ad0de71708dbe6e2026f7dbe0b3e
            log4(nonIndexedPos, nonIndexedLength, signatureHash, operator, from, to)
        }
        function emitApprovalForAll(owner_, operator, approved) {
            let signatureHash := 0x17307eab39f0d10f39a5de51c62fbeed3908d6cae33b571c0e059e61a10e9b90
            mstore(0, approved)
            log3(0, 0x20, signatureHash, owner_, operator)
        }
        

         /* ---------- utility functions ---------- */
         function lte(a, b) -> r {
            r := iszero(gt(a, b))
        }
        function gte(a, b) -> r {
            r := iszero(lt(a, b))
        }
        function safeAdd(a, b) -> r {
            r := add(a, b)
            if or(lt(r, a), lt(r, b)) { revert(0, 0) }
        }
        function safeSub(a, b) -> r {
            require(lte(b, a))
            r := sub(a, b)
        }
        function calledByOwner() -> cbo {
            cbo := eq(owner(), caller())
        }
        function revertIfZeroAddress(addr) {
            require(addr)
        }
        function require(condition) {
            if iszero(condition) { revert(0, 0) }
        }
      }
    }
  }