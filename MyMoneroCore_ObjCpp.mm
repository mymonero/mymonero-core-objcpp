//
//  MyMoneroCore_ObjCpp.mm
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
#import "MyMoneroCore_ObjCpp.h"
#include "monero_wallet_utils.hpp"
#include "monero_paymentID_utils.hpp"
#include "monero_transfer_utils.hpp"
#include "monero_key_image_utils.hpp"
#include "monero_fork_rules.hpp"
//
#include "string_tools.h"
using namespace epee;
//
#include "wallet2_transfer_utils.h"
//
//
// Accessory types
//
@implementation Monero_DecodedAddress_RetVals
@end
//
//
// Constants
//
// TODO: obtain these from C++ declns somehow
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_Low = 1;
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_MedLow = 2;
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_MedHigh = 3;
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_High = 4;
//
//
// Principal type
//
@implementation MyMoneroCore_ObjCpp
//
// Class
+ (NSString *)retValDictKey__ErrStr
{
	return @"ErrStr";
}
+ (NSString *)retValDictKey__Value
{
	return @"Value";
}
//
// Instance
- (BOOL)newlyCreatedWallet:(NSString *)wordsetName
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
	monero_wallet_utils::WalletDescriptionRetVals retVals;
	bool r = monero_wallet_utils::new_wallet(
		mnemonic_language,
		retVals,
		false // isTestnet
	);
	bool did_error = retVals.did_error;
	if (!r) {
		NSAssert(did_error, @"Illegal: fail flag but !did_error");
		_doFn_withErrStr([NSString stringWithUTF8String:(*retVals.err_string).c_str()]);
		return NO;
	}
	NSAssert(!did_error, @"Illegal: success flag but did_error");
	//
	monero_wallet_utils::WalletDescription walletDescription = *(retVals.optl__desc);
	std::string mnemonic_string = walletDescription.mnemonic_string;
	std::string address_string = walletDescription.address_string;
	std::string sec_viewKey_hexString = string_tools::pod_to_hex(walletDescription.sec_viewKey);
	std::string sec_spendKey_hexString = string_tools::pod_to_hex(walletDescription.sec_spendKey);
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(walletDescription.pub_viewKey);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(walletDescription.pub_spendKey);
	//
	NSString *seed_NSString = [NSString stringWithUTF8String:walletDescription.sec_seed_string.c_str()];
	NSString *mnemonic_NSString = [NSString stringWithUTF8String:mnemonic_string.c_str()];
	NSString *address_NSString = [NSString stringWithUTF8String:address_string.c_str()];
	NSString *sec_viewKey_NSString = [NSString stringWithUTF8String:sec_viewKey_hexString.c_str()];
	NSString *sec_spendKey_NSString = [NSString stringWithUTF8String:sec_spendKey_hexString.c_str()];
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:pub_viewKey_hexString.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:pub_spendKey_hexString.c_str()];
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
	return YES;
}
//
//
- (NSDictionary *)mnemonicStringFromSeedHex:(NSString *)seed_NSString
						mnemonicWordsetName:(NSString *)wordsetName
{
	std::string sec_hexString = std::string(seed_NSString.UTF8String);
	std::string mnemonic_string;
	std::string mnemonic_language = std::string(wordsetName.UTF8String);
	NSUInteger sec_hexString_length = seed_NSString.length;
	//
	bool r = false;
	if (sec_hexString_length == crypto::sec_seed_hex_string_length) { // normal seed
		crypto::secret_key sec_seed;
		r = string_tools::hex_to_pod(sec_hexString, sec_seed);
		if (!r) {
			return @{
				[[self class] retValDictKey__ErrStr]: NSLocalizedString(@"Invalid seed", comment:@"")
			};
		}
		r = crypto::ElectrumWords::bytes_to_words(sec_seed, mnemonic_string, mnemonic_language);
	} else if (sec_hexString_length == crypto::legacy16B__sec_seed_hex_string_length) {
		crypto::legacy16B_secret_key legacy16B_sec_seed;
		r = string_tools::hex_to_pod(sec_hexString, legacy16B_sec_seed);
		if (!r) {
			return @{
				[[self class] retValDictKey__ErrStr]: NSLocalizedString(@"Invalid seed", comment: @"")
			};
		}
		r = crypto::ElectrumWords::bytes_to_words(legacy16B_sec_seed, mnemonic_string, mnemonic_language); // called with the legacy16B version
	} else {
		return @{
			[[self class] retValDictKey__ErrStr]: NSLocalizedString(@"Invalid seed length", comment: @"")
		};
	}
	if (!r) {
		return @{
			[[self class] retValDictKey__ErrStr] : NSLocalizedString(@"Couldn't get mnemonic from hex seed", comment: @"")
		};
	}
	NSString *mnemonicString = [NSString stringWithUTF8String:mnemonic_string.c_str()];
	return @{
		[[self class] retValDictKey__Value]: mnemonicString
	};
}
//
- (BOOL)seedAndKeysFromMnemonic:(NSString *)mnemonic_NSString
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
	monero_wallet_utils::WalletDescriptionRetVals retVals;
	BOOL r = monero_wallet_utils::wallet_with(
		mnemonic_string,
		mnemonic_language,
		retVals
	);
	bool did_error = retVals.did_error;
	if (!r) {
		NSAssert(did_error, @"Illegal: fail flag but !did_error");
		_doFn_withErrStr([NSString stringWithUTF8String:(*retVals.err_string).c_str()]);
		return NO;
	}
	NSAssert(!did_error, @"Illegal: success flag but did_error");
	//
	monero_wallet_utils::WalletDescription walletDescription = *(retVals.optl__desc);
	//
//	std::string mnemonic_string = walletDescription.mnemonic_string;
	std::string address_string = walletDescription.address_string;
	std::string sec_viewKey_hexString = string_tools::pod_to_hex(walletDescription.sec_viewKey);
	std::string sec_spendKey_hexString = string_tools::pod_to_hex(walletDescription.sec_spendKey);
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(walletDescription.pub_viewKey);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(walletDescription.pub_spendKey);
	//
	NSString *seed_NSString = [NSString stringWithUTF8String:walletDescription.sec_seed_string.c_str()];
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
	return YES;
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
	if (outputs.did_error) {
		NSString *errStr = [NSString stringWithUTF8String:(*outputs.err_string).c_str()];
		_doFn_withErrStr(errStr);
		return;
	}
	NSAssert(didSucceed, @"Found unexpectedly didSucceed=false without an error");
	NSAssert(outputs.isValid, @"Found unexpectedly invalid wallet components without an error");
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
- (Monero_DecodedAddress_RetVals *)decodedAddress:(NSString *)addressString isTestnet:(BOOL)isTestnet
{
	Monero_DecodedAddress_RetVals *retVals = [Monero_DecodedAddress_RetVals new];
	//
	cryptonote::address_parse_info info;
	bool didSucceed = cryptonote::get_account_address_from_str(info, isTestnet, std::string(addressString.UTF8String));
	if (didSucceed == false) {
		retVals.errStr_orNil = NSLocalizedString(@"Invalid address", nil);
		//
		return retVals;
	}
	cryptonote::account_public_address address = info.address;
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(address.m_view_public_key);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(address.m_spend_public_key);
	//
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:pub_viewKey_hexString.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:pub_spendKey_hexString.c_str()];
	NSString *paymentID_NSString_orNil = nil;
	if (info.has_payment_id == true) {
		crypto::hash8 payment_id = info.payment_id;
		std::string payment_id_hexString = string_tools::pod_to_hex(payment_id);
		paymentID_NSString_orNil = [NSString stringWithUTF8String:payment_id_hexString.c_str()];
	}
	{
		retVals.pub_viewKey_NSString = pub_viewKey_NSString;
		retVals.pub_spendKey_NSString = pub_spendKey_NSString;
		retVals.paymentID_NSString_orNil = paymentID_NSString_orNil;
		retVals.isSubaddress = info.is_subaddress;
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
	return [NSString stringWithUTF8String:monero_transfer_utils::new_dummy_address_string_for_rct_tx(
		false // isTestnet
	).c_str()];
}
//
+ (uint32_t)fixedRingsize
{
	return monero_transfer_utils::fixed_ringsize();
}
+ (uint32_t)fixedMixinsize
{
	return monero_transfer_utils::fixed_mixinsize();
}
+ (uint32_t)default_priority
{
	return MyMoneroCore_ObjCpp_SimplePriority_MedLow; // this is set to 2 rather than 1 as in monero-src; this value 2 corresponds to .mlow in Swift-land; it's chosen to maintain speediness for lightwallet use-cases as a default and can always be set down to 1 as desired
}
//
+ (uint64_t)estimatedTxNetworkFeeWithFeePerKB:(uint64_t)fee_per_kb
	priority:(uint32_t)priority
{
	bool is_testnet = false;
	monero_transfer_utils::use_fork_rules_fn_type use_fork_rules_fn = [
		is_testnet
	] (
		uint8_t version,
		int64_t early_blocks
	) -> bool {
		// This is temporary until we have the fork rules supplied by the server
		if (version >= monero_fork_rules::get_bulletproof_fork(is_testnet)) {
			return false;
		}
		return true;
	};
	uint64_t fee_multiplier = monero_transfer_utils::get_fee_multiplier(
		priority,
		[self default_priority],
		monero_transfer_utils::get_fee_algorithm(use_fork_rules_fn),
		use_fork_rules_fn
	);
	std::vector<uint8_t> extra; // blank extra
	bool bulletproof = false; // for now...
	size_t est_tx_size = monero_transfer_utils::estimate_rct_tx_size(2, [self fixedMixinsize], 2, extra.size(), bulletproof); // typically ~14kb post-rct, pre-bulletproofs
	uint64_t estimated_fee = monero_transfer_utils::calculate_fee(
		fee_per_kb,
		est_tx_size,
		fee_multiplier
	);
	
	return estimated_fee;
}

//
- (NSString *)new_integratedAddrFromStdAddr:(NSString *)std_address_NSString andShortPID:(NSString *)short_paymentID isTestnet:(BOOL)isTestnet
{
	std::string payment_id__string = std::string(short_paymentID.UTF8String);
	crypto::hash8 payment_id_short;
	bool didParse = monero_paymentID_utils::parse_short_payment_id(payment_id__string, payment_id_short);
	if (!didParse) {
		return nil;
	}
	cryptonote::address_parse_info info;
	bool didSucceed = cryptonote::get_account_address_from_str(info, isTestnet, std::string(std_address_NSString.UTF8String));
	if (didSucceed == false) {
		return nil;
	}
	if (info.has_payment_id != false) {
		// could even throw / fatalError here
		return nil; // that was not a std_address!
	}
	std::string int_address_string = cryptonote::get_account_integrated_address_as_str(
		isTestnet,
		info.address,
		payment_id_short
	);
	NSString *int_address_NSString = [NSString stringWithUTF8String:int_address_string.c_str()];
	//
	return int_address_NSString;
}
- (NSString *)new_integratedAddrFromStdAddr:(NSString *)std_address_NSString andShortPID:(NSString *)short_paymentID // mainnet
{
	return [self
		new_integratedAddrFromStdAddr:std_address_NSString
		andShortPID:short_paymentID
		isTestnet:NO];
}
//
- (NSString *)new_keyImageFrom_tx_pub_key:(NSString *)tx_pub_key_NSString
							 sec_spendKey:(NSString *)sec_spendKey_NSString
							  sec_viewKey:(NSString *)sec_viewKey_NSString
							 pub_spendKey:(NSString *)pub_spendKey_NSString
								out_index:(uint64_t)out_index
{
	crypto::secret_key sec_viewKey{};
	crypto::secret_key sec_spendKey{};
	crypto::public_key pub_spendKey{};
	crypto::public_key tx_pub_key{};
	{ // Would be nice to find a way to avoid converting these back and forth
		bool r = false;
		r = string_tools::hex_to_pod(std::string(sec_viewKey_NSString.UTF8String), sec_viewKey);
		NSAssert(r, @"Invalid secret view key");
		r = string_tools::hex_to_pod(std::string(sec_spendKey_NSString.UTF8String), sec_spendKey);
		NSAssert(r, @"Invalid secret spend key");
		r = string_tools::hex_to_pod(std::string(pub_spendKey_NSString.UTF8String), pub_spendKey);
		NSAssert(r, @"Invalid public spend key");
		r = string_tools::hex_to_pod(std::string(tx_pub_key_NSString.UTF8String), tx_pub_key);
		NSAssert(r, @"Invalid tx pub key");
	}
	monero_key_image_utils::KeyImageRetVals retVals;
	{
		bool r = monero_key_image_utils::new__key_image(pub_spendKey, sec_spendKey, sec_viewKey, tx_pub_key, out_index, retVals);
		if (!r) {
			return nil; // TODO: return error string? (unwrap optional)
		}
	}
	std::string key_image_hex_string = string_tools::pod_to_hex(retVals.calculated_key_image);
	NSString *key_image_hex_NSString = [NSString stringWithUTF8String:key_image_hex_string.c_str()];
	//
	return key_image_hex_NSString;
}
//

@end
