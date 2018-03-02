//
//  MyMoneroCore_ObjCpp.h
//  MyMonero
//
//  Created by Paul Shapiro on 11/22/17.
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
//
//
#import <Foundation/Foundation.h>
//
@interface Monero_DecodedAddress_RetVals: NSObject

@property (nonatomic, copy) NSString *errStr_orNil;

@property (nonatomic, copy) NSString *pub_viewKey_NSString;
@property (nonatomic, copy) NSString *pub_spendKey_NSString;
@property (nonatomic) BOOL isSubaddress;
@property (nonatomic, copy) NSString *paymentID_NSString_orNil;

@end
//
extern uint32_t const MyMoneroCore_ObjCpp_SimplePriority_Low;
extern uint32_t const MyMoneroCore_ObjCpp_SimplePriority_MedLow;
extern uint32_t const MyMoneroCore_ObjCpp_SimplePriority_MedHigh;
extern uint32_t const MyMoneroCore_ObjCpp_SimplePriority_High;
//
@interface MyMoneroCore_ObjCpp : NSObject
//
// Return value dictionary keys
+ (NSString *)retValDictKey__ErrStr;
+ (NSString *)retValDictKey__Value; // used for single value returns… you should force-cast the type… e.g. "as! String" for -mnemonicStringFromSeedHex:…
//
//
+ (BOOL)newlyCreatedWallet:(NSString *)wordsetName
						fn:(void (^)
							(
							 NSString *errStr_orNil,
							 // OR
							 NSString *seed_NSString,
							 NSString *mnemonic_NSString,
							 NSString *address_NSString,
							 NSString *sec_viewKey_NSString,
							 NSString *sec_spendKey_NSString,
							 NSString *pub_viewKey_NSString,
							 NSString *pub_spendKey_NSString
							 )
							)fn;

+ (NSDictionary *)mnemonicStringFromSeedHex:(NSString *)seed_NSString
						mnemonicWordsetName:(NSString *)wordsetName;

+ (BOOL)seedAndKeysFromMnemonic:(NSString *)mnemonic_NSString
					wordsetName:(NSString *)wordsetName
							 fn:(void (^)
								 (
								  NSString *errStr_orNil,
								  // OR
								  NSString *seed_NSString,
								  NSString *mnemonic_NSString,
								  NSString *address_NSString,
								  NSString *sec_viewKey_NSString,
								  NSString *sec_spendKey_NSString,
								  NSString *pub_viewKey_NSString,
								  NSString *pub_spendKey_NSString
								  )
								 )fn;

+ (void)verifiedComponentsForOpeningExistingWalletWithAddress:(NSString *)address_NSString
												  sec_viewKey:(NSString *)sec_viewKey
							    sec_spendKey_orNilForViewOnly:(NSString *)sec_spendKey_orNilForViewOnly
											   sec_seed_orNil:(NSString *)sec_seed_NSString_orNil
									 wasANewlyGeneratedWallet:(BOOL)wasANewlyGeneratedWallet
														   fn:(void (^)
															  (
															   NSString *errStr_orNil,
															   // OR
															   NSString *seed_NSString_orNil,
															   //
															   NSString *address_NSString,
															   NSString *sec_viewKey_NSString_orNil,
															   NSString *sec_spendKey_NSString,
															   NSString *pub_viewKey_NSString,
															   NSString *pub_spendKey_NSString,
															   BOOL isInViewOnlyMode
															   )
															  )fn;
//
+ (Monero_DecodedAddress_RetVals *)decodedAddress:(NSString *)addressString isTestnet:(BOOL)isTestnet;
//
+ (NSString *)new_short_plain_paymentID;
//
+ (NSString *)new_integratedAddrFromStdAddr:(NSString *)std_address_NSString andShortPID:(NSString *)short_paymentID isTestnet:(BOOL)isTestnet;
+ (NSString *)new_integratedAddrFromStdAddr:(NSString *)std_address_NSString andShortPID:(NSString *)short_paymentID; // mainnet
//
+ (NSString *)new_fakeAddressForRCTTx;
//
+ (uint32_t)fixedRingsize; // NOTE: This is not the mixin, which would be fixedRingsize-1
+ (uint32_t)fixedMixinsize; // NOTE: This is not the ringsize, which would be fixedMixin+1
//
+ (uint32_t)default_priority;
+ (uint64_t)estimatedTxNetworkFeeWithFeePerKB:(uint64_t)fee_per_kb
	priority:(uint32_t)priority;
//
+ (NSString *)new_keyImageFrom_tx_pub_key:(NSString *)tx_pub_key_NSString
				sec_spendKey:(NSString *)sec_spendKey_NSString
				sec_viewKey:(NSString *)sec_viewKey_NSString
				pub_spendKey:(NSString *)pub_spendKey_NSString
				out_index:(uint64_t)out_index;
//
@end
