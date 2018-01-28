//
//  LightWallet3Wrapper.h
//  MyMonero
//
//  Created by Paul Shapiro on 1/17/18.
//  Copyright (c) 2014-2018, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
//
//
// Accessory Types
//
//
// Deprecated due to lack of use - TODO: delete
//@interface Monero_Bridge_SpentOutputDescription: NSObject
//
//@property (nonatomic) uint64_t amount;
//@property (nonatomic) uint64_t out_index;
//@property (nonatomic) uint32_t mixin;
//
//@property (nonatomic, copy) NSString *tx_pub_key;
//@property (nonatomic, copy) NSString *key_image;
//
//@end
//
//
// NOTE: It'd be nice to avoid the duplicativeness of these Monero_Bridge classes and instances but it allows us to keep the Swift implementation in Swift… maybe eventually bring the Swift obj to ObjC land to avoid this
@interface Monero_Bridge_HistoricalTransactionRecord: NSObject

@property (nonatomic) uint64_t amount;
@property (nonatomic) BOOL isIncoming;

@property (nonatomic) uint32_t mixin;
@property (nonatomic) NSDate * _Nonnull timestampDate;
@property (nonatomic) uint64_t unlockTime;
@property (nonatomic) uint64_t height;
@property (nonatomic) BOOL mempool; // aka is_unconfirmed

@property (nonatomic, copy) NSString * _Nonnull txHash; // cannot call it -hash
@property (nonatomic, copy) NSString * _Nullable paymentId; // may be nil

@end
//

@interface Monero_Bridge_GetRandomOutsBlock_RetVals: NSObject

@property (nonatomic, copy) NSString * _Nullable errStr_orNil;

//@class MoneroRandomAmountAndOutputs;
//@class MoneroRandomOutputDescription;
@property (nonatomic, strong) NSArray * _Nullable mixOuts;

@end

//
//
// Principal Type
//
@interface LightWallet3Wrapper: NSObject
//
// Imperatives - Lifecycle
- (_Nonnull instancetype)init; // designated initializer
// then call one of
- (BOOL)setupWalletWith_mnemonicSeed:(NSString * _Nonnull)mnemonicSeed_NSString
					mnemonicLanguage:(NSString * _Nonnull)mnemonicLanguage_NSString;
- (BOOL)setupWalletWith_address:(NSString * _Nonnull)address_NSString
						viewkey:(NSString * _Nonnull)viewkey_NSString
					   spendkey:(NSString * _Nonnull)spendkey_NSString;
@property (nonatomic, readonly) BOOL hasLWBeenInitialized; // is set to YES after successful call to any of the above -setupWalletWith_*
//
// Imperatives - Runtime - Server API response
- (BOOL)ingestJSONString_addressInfo:(NSString * _Nonnull)response_jsonString or_didError:(BOOL)didError; // returns NO on parse err
- (BOOL)ingestJSONString_addressTxs:(NSString * _Nonnull)response_jsonString; // returns NO on parse err
- (BOOL)ingestJSONString_unspentOuts:(NSString * _Nonnull)response_jsonString mixinSize:(uint32_t)mixinSize;
//
// Accessors
- (uint64_t)scanned_height;
- (uint64_t)scanned_block_height;
- (uint64_t)scan_start_height;
- (uint64_t)transaction_height;
- (uint64_t)blockchain_height;

- (uint64_t)locked_balance;
- (uint64_t)total_sent;
- (uint64_t)total_received;

- (NSString * _Nonnull)address;
- (NSString * _Nonnull)view_key__private;
- (NSString * _Nonnull)spend_key__private;

- (NSArray * _Nonnull)timeOrdered_historicalTransactionRecords; // [Monero_Bridge_HistoricalTransactionRecord]; TODO: this used to sort by b.id-a.id in JS… is timestamp sort ok?
//
// Transferring
// NOTE: before you call -new_serializedSigned…, set be sure to have set getRandomOuts__block
@property (nonatomic, copy) void (^ _Nullable getRandomOuts__block)(void(^ _Nonnull cb)(Monero_Bridge_GetRandomOutsBlock_RetVals * _Nonnull retVals));

- (void)new_serializedSignedTransactionWithTo_address:(NSString * __nonnull)to_address
								  amount_float_string:(NSString * __nonnull)amount_float_string
										   payment_id:(NSString * __nullable)optl__payment_id
											 priority:(uint32_t)simple_priority // this must be a number between (not including) 0 and 5
												   fn:(void(^ __nonnull)(
																		 NSString * __nullable errStr,
																		 NSString * __nullable serializedSignedTransactionString
															   )
													   )fn;
@end
