//
//  MyMoneroCore_ObjCpp.h
//  MyMonero
//
//  Created by Paul Shapiro on 11/22/17.
//  Copyright (c) 2014-2017, MyMonero.com
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
// Bridged types
@class MoneroOutputDescription;
@class MoneroRandomAmountAndOutputs;
@class MoneroRandomOutputDescription;
@class SendFundsTargetDescription;
@class MoneroKeyDuo;
//
//
@interface MyMoneroCore_ObjCpp : NSObject

- (void)newlyCreatedWallet:(NSString *)wordsetName
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

- (void)mnemonicStringFromSeedHex:(NSString *)seed_NSString
			  mnemonicWordsetName:(NSString *)wordsetName
							   fn:(void (^)
								   (
									NSString *errStr_orNil,
									// OR
									NSString *mnemonic_NSString
									)
								   )fn;

- (void)seedAndKeysFromMnemonic:(NSString *)mnemonic_NSString
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

-(void)verifiedComponentsForOpeningExistingWalletWithAddress:(NSString *)address_NSString
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

- (void)decodedAddress:(NSString *)addressString
					fn:(void(^)(
								NSString *errStr_orNil,
								//
								NSString *pub_viewKey_NSString,
								NSString *pub_spendKey_NSString,
								NSString *paymentID_NSString_orNil
								)
						)fn;
//
- (NSString *)new_long_plain_paymentID;
- (NSString *)new_short_plain_paymentID;
//
- (NSString *)new_fakeAddressForRCTTx;

- (void)new_transactionWith_sec_keyDuo:(MoneroKeyDuo *)sec_keyDuo
					 splitDestinations:(NSArray *)splitDestinations //: [SendFundsTargetDescription] (LW generic screws with method sig for some reason)
							 usingOuts:(NSArray *)usingOuts //: [MoneroOutputDescription]
							   mixOuts:(NSArray *)mixOuts //: [MoneroRandomAmountAndOutputs]
					fake_outputs_count:(NSUInteger)fake_outputs_count
			   fee_amount_bigIntString:(NSString *)fee_amount_bigIntString
							payment_id:(NSString *)optl__payment_id_NSString
		  ifPIDEncrypt_realDestViewKey:(NSString *)ifPIDEncrypt_realDestViewKey_NSString
									fn:(void(^)(
												NSString *errStr_orNil,
												//
												NSArray<NSString *> *rct_signatures,
												NSString *extra
												)
										)fn;


@end
