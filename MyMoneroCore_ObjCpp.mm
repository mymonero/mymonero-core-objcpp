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
//
#include "string_tools.h"
using namespace epee;
//
#include "wallet2_transfer_utils.h"
//
@implementation MyMoneroCore_ObjCpp
//
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
		_doFn_withErrStr([NSString stringWithUTF8String:(*retVals.optl__err_string).c_str()]);
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
			fn(NSLocalizedString(@"Invalid seed", ""), nil);
			return;
		}
		r = crypto::ElectrumWords::bytes_to_words(sec_seed, mnemonic_string, mnemonic_language);
	} else if (sec_hexString_length == crypto::legacy16B__sec_seed_hex_string_length) {
		crypto::legacy16B_secret_key legacy16B_sec_seed;
		r = string_tools::hex_to_pod(sec_hexString, legacy16B_sec_seed);
		if (!r) {
			fn(NSLocalizedString(@"Invalid seed", ""), nil);
			return;
		}
		r = crypto::ElectrumWords::bytes_to_words(legacy16B_sec_seed, mnemonic_string, mnemonic_language); // called with the legacy16B version
	} else {
		fn(NSLocalizedString(@"Invalid seed length", ""), nil);
		return;
	}
	if (!r) {
		fn(NSLocalizedString(@"Couldn't get mnemonic from hex seed", nil), nil);
		return;
	}
	NSString *mnemonic_NSString = [NSString stringWithUTF8String:mnemonic_string.c_str()];
	fn(nil, mnemonic_NSString);
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
		_doFn_withErrStr([NSString stringWithUTF8String:(*retVals.optl__err_string).c_str()]);
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
	if (outputs.didError) {
		NSString *errStr = [NSString stringWithUTF8String:outputs.err_string.c_str()];
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
- (NSUInteger)fixedRingsize
{
	return monero_transfer_utils::fixed_ringsize();
}
- (NSUInteger)fixedMixinsize
{
	return monero_transfer_utils::fixed_mixinsize();
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
			return nil; // TODO: return error string?
		}
	}
	std::string key_image_hex_string = string_tools::pod_to_hex(retVals.calculated_key_image);
	NSString *key_image_hex_NSString = [NSString stringWithUTF8String:key_image_hex_string.c_str()];
	//
	return key_image_hex_NSString;
}
//
- (void)new_serializedSignedTransactionTo_address:(NSString *)to_address
									   payment_id:(NSString *)optl__payment_id_NSString
							  amount_float_NSString:(NSString *)amount_float_NSString
									  sec_viewKey:(NSString *)sec_viewKey
									 sec_spendKey:(NSString *)sec_spendKey
								   blockchain_size:(uint64_t)blockchain_size
										 priority:(uint32_t)priority
									   unusedOuts:(NSArray *)unusedOuts // [Monero_OutputDescription_BridgeObj]
							 getRandomOuts__block:(void(^ __nonnull )(void(^__nonnull)(Monero_GetRandomOutsBlock_RetVals * __nonnull cb)))getRandomOuts__block
											   fn:(void(^ __nonnull )(
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
	std::string to_address_string = std::string(to_address.UTF8String);
	std::string amount_float_string = std::string(amount_float_NSString.UTF8String);
	std::string sec_viewKey_string = std::string(sec_viewKey.UTF8String);
	std::string sec_spendKey_string = std::string(sec_spendKey.UTF8String);
	//
	const std::string *paymentID_string__ptr = nullptr;
	std::string paymentID_string;
	if (optl__payment_id_NSString) {
		paymentID_string = std::string(optl__payment_id_NSString.UTF8String);
		paymentID_string__ptr = &paymentID_string;
	}
	//
	// TODO: obtain this, and unconfirmed txs, by porting Jaquee's parsing code
	std::vector<tools::wallet2::transfer_details> transfers;
	{
		
	}
	//
	std::function<bool(
		std::vector<std::vector<tools::wallet2::get_outs_entry>> &,
		const std::list<size_t> &,
		size_t
	)> get_random_outs_fn = [
		getRandomOuts__block
	] (std::vector<
	   std::vector<tools::wallet2::get_outs_entry>> &outs,
	   const std::list<size_t> &selected_transfers,
	   size_t fake_outputs_count
	) -> bool {
		//
		// TODO pass fake_outputs_count etc as required to getRandomOuts
		getRandomOuts__block(^(Monero_GetRandomOutsBlock_RetVals *retVals)
		{
			NSLog(@"retvals %@", retVals);
			// TODO: now that we have retVals
			if (retVals.errStr_orNil != nil) {
				// TODO: return nil to create tx calling this random out and fail there … which should trigger fn to be called
				return; // prevent fallthrough
			}
			//
			// ---TODO---: pass retVals mixOuts back after adding callback or some other way to return…
			//
		});
		//
		return false; // TODO: need/want this flag?
	};
	//
	std::set<uint32_t> subaddr_indices; // TODO?
	//
	monero_transfer_utils::CreateTx_Args args =
	{
		sec_viewKey_string,
		sec_spendKey_string,
		//
		to_address_string,
		amount_float_string,
		//
		transfers,
		get_random_outs_fn,
		//
		blockchain_size,
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
		0, // current_subaddress_account TODO??
		subaddr_indices,
		//
		false, // is_testnet
		true, // is_trusted_daemon
		true // is_lightwallet
	};
	monero_transfer_utils::CreateTx_RetVals retVals = {};
	BOOL didSucceed = monero_transfer_utils::create_signed_transaction(args, retVals);
	if (retVals.didError) {
		NSString *errStr = [NSString stringWithUTF8String:retVals.err_string.c_str()];
		_doFn_withErrStr(errStr);
		return;
	}
	NSAssert(didSucceed, @"Found unexpectedly didSucceed=false without an error");
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
