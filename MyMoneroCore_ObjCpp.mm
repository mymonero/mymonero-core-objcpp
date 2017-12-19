//
//  MyMoneroCore_ObjCpp.mm
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
#import "MyMoneroCore_ObjCpp.h"
#include "monero_wallet_utils.hpp"
#include "monero_address_utils.hpp"
#include "monero_paymentID_utils.hpp"
#include "monero_transfer_utils.hpp"
//
#include "include_base_utils.h"
using namespace epee;
//
@implementation MyMoneroCore_ObjCpp
//
- (void)newlyCreatedWallet:(NSString *)wordsetName
						fn:(void (^)
							(
							 NSString *errStr_orNil,
							 // OR
							 // TODO: possible to return a singular container object/struct which holds typed strings instead?
							 NSString *seed_NSString,
							 NSString *mnemonic_NSString,
							 NSString *address_NSString,
							 NSString *sec_viewKey_NSString,
							 NSString *sec_spendKey_NSString,
							 NSString *pub_viewKey_NSString,
							 NSString *pub_spendKey_NSString
							 )
							)fn
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		fn(
		   errStr,
		   //
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil
		   );
	};
	std::string mnemonic_language = std::string(wordsetName.UTF8String);
	boost::optional<monero_wallet_utils::WalletDescription> optl_walletDescription = monero_wallet_utils::new_wallet(
		mnemonic_language,
		false // isTestnet
	);
	if (!optl_walletDescription) {
		_doFn_withErrStr(NSLocalizedString(@"Unknown error", nil));
		return;
	}
	monero_wallet_utils::WalletDescription walletDescription = *optl_walletDescription;
	//
	std::string sec_seed_hexString = string_tools::pod_to_hex(walletDescription.sec_seed);
	std::string mnemonic_string = walletDescription.mnemonic_string;
	std::string address_string = walletDescription.address_string;
	std::string sec_viewKey_hexString = string_tools::pod_to_hex(walletDescription.sec_viewKey);
	std::string sec_spendKey_hexString = string_tools::pod_to_hex(walletDescription.sec_spendKey);
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(walletDescription.pub_viewKey);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(walletDescription.pub_spendKey);
	//
	NSString *seed_NSString = [NSString stringWithUTF8String:sec_seed_hexString.c_str()];
	NSString *mnemonic_NSString = [NSString stringWithUTF8String:mnemonic_string.c_str()];
	NSString *address_NSString = [NSString stringWithUTF8String:address_string.c_str()];
	NSString *sec_viewKey_NSString = [NSString stringWithUTF8String:sec_viewKey_hexString.c_str()];
	NSString *sec_spendKey_NSString = [NSString stringWithUTF8String:sec_spendKey_hexString.c_str()];
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:pub_viewKey_hexString.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:pub_spendKey_hexString.c_str()];
	//
	// TODO: handle and pass through returned error … such as upon illegal mnemonic_language
	//
	fn(
	   nil,
	   //
	   seed_NSString,
	   mnemonic_NSString,
	   address_NSString,
	   sec_viewKey_NSString,
	   sec_spendKey_NSString,
	   pub_viewKey_NSString,
	   pub_spendKey_NSString
	);
}
//
- (void)mnemonicStringFromSeedHex:(NSString *)seed_NSString
		   mnemonicWordsetName:(NSString *)wordsetName
							fn:(void (^)
								(
								 NSString *errStr_orNil,
								 // OR
								 NSString *mnemonic_NSString
								 )
								)fn
{
	std::string mnemonic_language = std::string(wordsetName.UTF8String);
	crypto::secret_key sec_seed;
	{
		std::string sec_hexString = std::string(seed_NSString.UTF8String);
		string_tools::hex_to_pod(sec_hexString, sec_seed);
	}
	// TODO: any way to assert sec_seed initialized here..? necessary?
	boost::optional<std::string> optl__mnemonic_string = monero_wallet_utils::mnemonic_string_from(
		sec_seed,
		mnemonic_language
	);
	if (!optl__mnemonic_string) {
		fn(NSLocalizedString(@"Unable to obtain mnemonic from seed", nil), nil);
		return;
	}
	NSString *mnemonic_NSString = [NSString stringWithUTF8String:(*optl__mnemonic_string).c_str()];
	fn(nil, mnemonic_NSString);
}
//
- (void)seedAndKeysFromMnemonic:(NSString *)mnemonic_NSString
				  	wordsetName:(NSString *)wordsetName
							 fn:(void (^)
								 (
								  NSString *errStr_orNil,
								  // OR
								  // TODO: possible to return a singular container object/struct which holds typed strings instead?
								  NSString *seed_NSString,
								  NSString *mnemonic_NSString,
								  NSString *address_NSString,
								  NSString *sec_viewKey_NSString,
								  NSString *sec_spendKey_NSString,
								  NSString *pub_viewKey_NSString,
								  NSString *pub_spendKey_NSString
								  )
								 )fn;
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		fn(
		   errStr,
		   //
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil
		);
	};
	std::string mnemonic_string = std::string(mnemonic_NSString.UTF8String);
	std::string mnemonic_language = std::string(wordsetName.UTF8String);
	boost::optional<monero_wallet_utils::WalletDescription> optl_walletDescription = monero_wallet_utils::wallet_with(
		mnemonic_string,
		mnemonic_language
	);
	if (!optl_walletDescription) {
		_doFn_withErrStr(NSLocalizedString(@"Unknown error", nil));
		return;
	}
	monero_wallet_utils::WalletDescription walletDescription = *optl_walletDescription;
	//
	std::string sec_seed_hexString = string_tools::pod_to_hex(walletDescription.sec_seed);
//	std::string mnemonic_string = walletDescription.mnemonic_string;
	std::string address_string = walletDescription.address_string;
	std::string sec_viewKey_hexString = string_tools::pod_to_hex(walletDescription.sec_viewKey);
	std::string sec_spendKey_hexString = string_tools::pod_to_hex(walletDescription.sec_spendKey);
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(walletDescription.pub_viewKey);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(walletDescription.pub_spendKey);
	//
	NSString *seed_NSString = [NSString stringWithUTF8String:sec_seed_hexString.c_str()];
	// TODO? we could assert that the returned mnemonic is the same as the input one
//	NSString *mnemonic_NSString = [NSString stringWithUTF8String:mnemonic_string.c_str()];
	NSString *address_NSString = [NSString stringWithUTF8String:address_string.c_str()];
	NSString *sec_viewKey_NSString = [NSString stringWithUTF8String:sec_viewKey_hexString.c_str()];
	NSString *sec_spendKey_NSString = [NSString stringWithUTF8String:sec_spendKey_hexString.c_str()];
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:pub_viewKey_hexString.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:pub_spendKey_hexString.c_str()];
	//
	// TODO: handle and pass through returned error … such as upon illegal mnemonic_language
	//
	fn(
	   nil,
	   //
	   seed_NSString,
	   mnemonic_NSString,
	   address_NSString,
	   sec_viewKey_NSString,
	   sec_spendKey_NSString,
	   pub_viewKey_NSString,
	   pub_spendKey_NSString
	);
}
//
- (void)verifiedComponentsForOpeningExistingWalletWithAddress:(NSString *)address_NSString
												 sec_viewKey:(NSString *)sec_viewKey_NSString
							   sec_spendKey_orNilForViewOnly:(NSString *)sec_spendKey_NSString_orNil
											  sec_seed_orNil:(NSString *)sec_seed_NSString_orNil
									wasANewlyGeneratedWallet:(BOOL)wasANewlyGeneratedWallet
														  fn:(void (^)
															  (
															   NSString *errStr_orNil,
															   // OR
															   NSString *seed_NSString_orNil,
															   //
															   NSString *address_NSString,
															   NSString *sec_viewKey_NSString,
															   NSString *sec_spendKey_NSString_orNil,
															   NSString *pub_viewKey_NSString,
															   NSString *pub_spendKey_NSString,
															   //
															   BOOL isInViewOnlyMode
															   )
															  )fn
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		fn(
		   errStr,
		   //
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   NO
		);
	};
	const std::string *sec_spendKey_string__ptr = nullptr;
	std::string sec_spendKey_string;
	if (sec_spendKey_NSString_orNil) {
		sec_spendKey_string = std::string(sec_spendKey_NSString_orNil.UTF8String);
		sec_spendKey_string__ptr = &sec_spendKey_string;
	}
	const std::string *sec_seed_string__ptr = nullptr;
	std::string sec_seed_string;
	if (sec_seed_NSString_orNil) {
		sec_seed_string = std::string(sec_seed_NSString_orNil.UTF8String);
		sec_seed_string__ptr = &sec_seed_string;
	}
	monero_wallet_utils::WalletComponentsToValidate inputs =
	{
		std::string(address_NSString.UTF8String),
		std::string(sec_viewKey_NSString.UTF8String),
		sec_spendKey_string__ptr,
		sec_seed_string__ptr,
		false, // isTestnet
	};
	monero_wallet_utils::WalletComponentsValidationResults outputs;
	BOOL didSucceed = monero_wallet_utils::validate_wallet_components_with(inputs, outputs);
	if (outputs.didError) {
		NSString *errStr = [NSString stringWithUTF8String:outputs.err_string.c_str()];
		_doFn_withErrStr(errStr);
		return;
	}
	NSCAssert(didSucceed, @"Found unexpectedly didSucceed=false without an error");
	NSCAssert(outputs.isValid, @"Found unexpectedly invalid wallet components without an error");
	//
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:outputs.pub_viewKey_string.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:outputs.pub_spendKey_string.c_str()];
	BOOL isInViewOnlyMode = outputs.isInViewOnlyMode;
	fn(
	   nil,
	   //
	   sec_seed_NSString_orNil,
	   //
	   address_NSString,
	   sec_viewKey_NSString,
	   sec_spendKey_NSString_orNil,
	   pub_viewKey_NSString,
	   pub_spendKey_NSString,
	   isInViewOnlyMode
	);
}
//
- (Monero_DecodedAddress_RetVals *)decodedAddress:(NSString *)addressString
{
	Monero_DecodedAddress_RetVals *retVals = [Monero_DecodedAddress_RetVals new];
	//
	boost::optional<monero_address_utils::DecodedAddress> optl__decoded_address = monero_address_utils::decoded_address(
		std::string(addressString.UTF8String)
	);
	if (!optl__decoded_address) {
		retVals.errStr_orNil = NSLocalizedString(@"Invalid address", nil);
		return retVals;
	}
	monero_address_utils::DecodedAddress decoded_address = *optl__decoded_address;
	cryptonote::account_public_address address = decoded_address.address_components;
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(address.m_view_public_key);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(address.m_spend_public_key);
	//
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:pub_viewKey_hexString.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:pub_spendKey_hexString.c_str()];
	NSString *paymentID_NSString_orNil = nil;
	if (decoded_address.optl__payment_id) {
		crypto::hash8 payment_id = *decoded_address.optl__payment_id;
		std::string payment_id_hexString = string_tools::pod_to_hex(payment_id);
		paymentID_NSString_orNil = [NSString stringWithUTF8String:payment_id_hexString.c_str()];
	}
	{
		retVals.pub_viewKey_NSString = pub_viewKey_NSString;
		retVals.pub_spendKey_NSString = pub_spendKey_NSString;
		retVals.paymentID_NSString_orNil = paymentID_NSString_orNil;
	}
	return retVals;
}

- (NSString *)new_long_plain_paymentID
{
	return [NSString stringWithUTF8String:string_tools::pod_to_hex(
		monero_paymentID_utils::new_long_plain_paymentID()
	).c_str()];	
}

- (NSString *)new_short_plain_paymentID
{
	return [NSString stringWithUTF8String:string_tools::pod_to_hex(
		monero_paymentID_utils::new_short_plain_paymentID()
	).c_str()];
}

- (NSString *)new_fakeAddressForRCTTx
{
	return [NSString stringWithUTF8String:monero_address_utils::new_dummy_address_string_for_rct_tx(
		false // isTestnet
	).c_str()];
}




- (NSString *)new_integratedAddrFromStdAddr:(NSString *)std_address_NSString andShortPID:(NSString *)short_paymentID
{
	std::string payment_id__string = std::string(short_paymentID.UTF8String);
	crypto::hash8 payment_id_short;
	bool didParse = monero_paymentID_utils::parse_short_payment_id(payment_id__string, payment_id_short);
	if (!didParse) {
		return nil;
	}
	boost::optional<monero_address_utils::DecodedAddress> optl__decoded_address = monero_address_utils::decoded_address(
		std::string(std_address_NSString.UTF8String)
	);
	if (!optl__decoded_address) {
		return nil;
	}
	cryptonote::account_public_address address_components = (*optl__decoded_address).address_components;
	//
	// NOTE: For this function, I am opting to just implement here, instead of in monero_address_utils
	bool is_testnet = false;
	std::string int_address_string = cryptonote::get_account_integrated_address_as_str(
		is_testnet,
		address_components,
		payment_id_short
	);
	NSString *int_address_NSString = [NSString stringWithUTF8String:int_address_string.c_str()];
	//
	return int_address_NSString;
}











// WIP:
- (void)new_transactionWith_sec_viewKey:(NSString *)sec_viewKey
						   sec_spendKey:(NSString *)sec_spendKey
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
										)fn
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		fn(
		   errStr,
		   //
		   nil,
		   nil
		);
	};
	//
	std::string sec_viewKey_string = std::string(sec_viewKey.UTF8String);
	std::string sec_spendKey_string = std::string(sec_spendKey.UTF8String);
	//
	uint32_t priority = 1; // TODO
	uint64_t blockchain_size = 0; // TODO
	//
	const std::string *paymentID_string__ptr = nullptr;
	std::string paymentID_string;
	if (optl__payment_id_NSString) {
		paymentID_string = std::string(optl__payment_id_NSString.UTF8String);
		paymentID_string__ptr = &paymentID_string;
	}
	//
	// TODO:
	std::vector<monero_transfer_utils::transfer_details> transfers;
	{
		
	}
	std::vector<cryptonote::tx_destination_entry> dsts;
	{
	
	}
	//
	const size_t fake_outs_count = 9; // TODO: declare this in function within monero_transfer_utils
	//
	monero_transfer_utils::CreateTx_Args args =
	{
		sec_viewKey_string,
		sec_spendKey_string,
		//
		dsts,
		transfers,
		//
		blockchain_size,
		fake_outs_count,
		0, // unlock_time
		priority,
		1, // default_priority
		//
		0, // min_output_count
		0, // min_output_value
		false, // merge_destinations - apparent default from wallet2
		//
		paymentID_string__ptr,
		//
		false // is_testnet
	};
	monero_transfer_utils::CreateTx_RetVals retVals;
	BOOL didSucceed = monero_transfer_utils::create_signed_transaction(args, retVals);
	if (retVals.didError) {
		NSString *errStr = [NSString stringWithUTF8String:retVals.err_string.c_str()];
		_doFn_withErrStr(errStr);
		return;
	}
	NSCAssert(didSucceed, @"Found unexpectedly didSucceed=false without an error");
	//
//	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:retVals.pub_viewKey_string.c_str()];
	//
	NSMutableArray<NSString *> *rct_signatures = [NSMutableArray new];
	NSString *extra = nil; // TODO
	//
	fn(
	   nil,
	   //
	   rct_signatures,
	   extra
   );
}

@end
