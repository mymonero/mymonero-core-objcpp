//
//  LightWallet3Wrapper.mm
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
//

#import "LightWallet3Wrapper.h"
#import "light_wallet3.hpp"
#include <string>
#include "portable_storage_template_helper.h"
#include "include_base_utils.h"
#include "cryptonote_basic.h"
#include "cryptonote_basic_impl.h"
#include "monero_key_utils.hpp"
#include "monero_wallet_utils.hpp"
#include "electrum-words.h"
#include "mnemonics/english.h"
#include "monero_transfer_utils.hpp"
#include <future>
//
using namespace epee; // for string_tools
using namespace tools;
using namespace crypto;
using namespace cryptonote;
//
//
// Accessory Types - Implementation
//
@implementation Monero_Bridge_HistoricalTransactionRecord
@end
//
//
// Principal Type - Interface
//
@interface LightWallet3Wrapper ()
{
	tools::light_wallet3 *_wallet__ptr;
}
@property (nonatomic, readwrite) BOOL hasLWBeenInitialized;
//
@end
//
//
// Principal Type - Implementation
//
@implementation LightWallet3Wrapper
//
//
// Lifecycle - Init
//
- (id)init
{
	self = [super init];
	if (self) {
		return [self setup];
	}
	return nil;
}
- (id)setup
{
	self.hasLWBeenInitialized = NO; // wait for .generate() to be called on wallet - mandatory
	//
	_wallet__ptr = new tools::light_wallet3(
		false/*testnet*/,
		false/*restricted*/
	);
//	_wallet__ptr->callback(self); // TODO
	if (!_wallet__ptr) {
		return nil;
	}
	_wallet__ptr->init(
		0 // m_upper_transaction_size_limit
	);
	//
	return self;
}
// THEN call one of these:
- (BOOL)setupWalletWith_mnemonicSeed:(NSString *)mnemonicSeed_NSString
					mnemonicLanguage:(NSString *)mnemonicLanguage_NSString
{
	std::string mnemonic_string = std::string(mnemonicSeed_NSString.UTF8String);
	std::string mnemonic_language_string = std::string(mnemonicLanguage_NSString.UTF8String);
	monero_wallet_utils::MnemonicDecodedSeed_RetVals retVals;
	bool r = monero_wallet_utils::decoded_seed(
		mnemonic_string,
		mnemonic_language_string,
		retVals
	);
	bool did_error = retVals.did_error;
	if (!r) {
		NSAssert(did_error, @"Illegal: fail flag but !did_error");
		NSAssert(false, @"Account generation problem with prevalidated mnemonic... code fault?");
		return NO;
	}
	NSAssert(!did_error, @"Illegal: success flag but did_error");
	//
	try {
		_wallet__ptr->generate(
			*retVals.optl__sec_seed,
			true/*recover*/,
			false/*two_random*/,
			retVals.from_legacy16B_lw_seed
		);
	} catch (const std::exception& e) {
		THROW_WALLET_EXCEPTION(tools::error::wallet_internal_error, std::string("failed to generate new wallet: ") + e.what());
		return false;
	}
	self.hasLWBeenInitialized = YES; // allow calls
	//
	return true;
}
- (BOOL)setupWalletWith_address:(NSString *)address_NSString
						viewkey:(NSString *)viewkey_NSString
					   spendkey:(NSString *)spendkey_NSString
{
	std::string field_address = std::string(address_NSString.UTF8String);
	std::string field_viewkey = std::string(viewkey_NSString.UTF8String);
	std::string field_spendkey = std::string(spendkey_NSString.UTF8String);
	//
	cryptonote::blobdata viewkey_data;
	if(!epee::string_tools::parse_hexstr_to_binbuff(field_viewkey, viewkey_data) || viewkey_data.size() != sizeof(crypto::secret_key)) {
		THROW_WALLET_EXCEPTION(tools::error::wallet_internal_error, "failed to parse view key secret key");
		return false;
	}
	crypto::secret_key viewkey = *reinterpret_cast<const crypto::secret_key*>(viewkey_data.data());
	//
	cryptonote::blobdata spendkey_data;
	if(!epee::string_tools::parse_hexstr_to_binbuff(field_spendkey, spendkey_data) || spendkey_data.size() != sizeof(crypto::secret_key)) {
		THROW_WALLET_EXCEPTION(tools::error::wallet_internal_error, "failed to parse spend key secret key");
		return false;
	}
	crypto::secret_key spendkey = *reinterpret_cast<const crypto::secret_key*>(spendkey_data.data());
	//
	try {
		cryptonote::account_public_address address;
		_wallet__ptr->generate(address, spendkey, viewkey);
	} catch (const std::exception& e) {
		THROW_WALLET_EXCEPTION(tools::error::wallet_internal_error, std::string("failed to generate new wallet: ") + e.what());
		return false;
	}
	self.hasLWBeenInitialized = YES; // allow calls
	//
	return true;
}
//
//
// Lifecycle - Deinit
//
- (void)dealloc
{
	delete _wallet__ptr;
	_wallet__ptr = NULL;
//	[super dealloc]; // ommitted b/c ARC enabled
}
//
//
// Interface - Imperatives - Receiving new data
//
- (BOOL)ingestJSONString_addressInfo:(NSString *)response_jsonString or_didError:(BOOL)didError
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return NO;
	}
	light_wallet3_server_api::COMMAND_RPC_GET_ADDRESS_INFO::response ires;
	if (didError) {
		_wallet__ptr->ingest__get_address_info(true, ires); // ires will have zeroed state by this point but method won't look at ires given didError
		return YES;
	}
	bool r = epee::serialization::load_t_from_json(ires, std::string(response_jsonString.UTF8String));
	_wallet__ptr->ingest__get_address_info(
		r == false, // in other words, treat it as an error if r is false
		ires
	);
	//
	return r;
}
- (BOOL)ingestJSONString_addressTxs:(NSString *)response_jsonString
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return NO;
	}
	light_wallet3_server_api::COMMAND_RPC_GET_ADDRESS_TXS::response ires;
	bool r = epee::serialization::load_t_from_json(ires, std::string(response_jsonString.UTF8String));
	if (!r) {
		return NO;
	}
	_wallet__ptr->ingest__get_address_txs(ires);
	//
	return YES;
}
- (BOOL)ingestJSONString_unspentOuts:(NSString *)response_jsonString mixinSize:(uint32_t)mixinSize
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return NO;
	}
	light_wallet3_server_api::COMMAND_RPC_GET_UNSPENT_OUTS::response ores;
	bool r = epee::serialization::load_t_from_json(ores, std::string(response_jsonString.UTF8String));
	if (!r) {
		return NO;
	}
	_wallet__ptr->ingest__get_unspent_outs(ores, mixinSize);
	//
	return YES;
}
//
//
// Interface - Accessors - Bridged parsed received data
//
- (uint64_t)scanned_height
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 0;
	}
	return _wallet__ptr->scanned_height();
}
- (uint64_t)scanned_block_height
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 0;
	}
	return _wallet__ptr->scanned_block_height();
}
- (uint64_t)scan_start_height
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 0;
	}
	return _wallet__ptr->scan_start_height();
}
- (uint64_t)transaction_height
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 0;
	}
	return _wallet__ptr->transaction_height();
}
- (uint64_t)blockchain_height
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 1;
	}
	return _wallet__ptr->blockchain_height();
}

- (uint64_t)locked_balance
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 0;
	}
	return _wallet__ptr->locked_balance();
}
- (uint64_t)total_sent
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 0;
	}
	return _wallet__ptr->total_sent();
}
- (uint64_t)total_received
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return 0;
	}
	return _wallet__ptr->total_received();
}
//
- (NSString *)address
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return nil;
	}
	return [NSString stringWithUTF8String:
		_wallet__ptr->get_account().get_public_address_str(
			_wallet__ptr->testnet()
		).c_str()
	];
}
- (NSString *)view_key__private
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return nil;
	}
	return [NSString stringWithUTF8String:
		string_tools::pod_to_hex(
			_wallet__ptr->get_account().get_keys().m_view_secret_key
		).c_str()
	];
}
- (NSString *)spend_key__private
{
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		return nil;
	}
	return [NSString stringWithUTF8String:
		string_tools::pod_to_hex(
			_wallet__ptr->get_account().get_keys().m_spend_secret_key
		).c_str()
	];
}

//- (Monero_Bridge_SpentOutputDescription *)_new_descFrom_spendOutput:(const cryptonote::COMMAND_RPC_GET_ADDRESS_INFO::spent_output &)so
//{
//	Monero_Bridge_SpentOutputDescription *desc = [Monero_Bridge_SpentOutputDescription new];
//	desc.amount = so.amount;
//	desc.out_index = so.out_index;
//	desc.mixin = so.mixin;
//	desc.tx_pub_key = [NSString stringWithUTF8String:so.tx_pub_key.c_str()];
//	desc.key_image = [NSString stringWithUTF8String:so.key_image.c_str()];
//	//
//	return desc;
//}
// Deprecated due to disuse
//- (NSArray *)spentOutputDescriptions
//{
//	NSMutableArray *list = [NSMutableArray new];
//	for (const auto &so: _wallet__ptr->spent_outputs()) {
//		[list addObject:[self _new_descFrom_spendOutput:so]];
//	}
//	return list;
//}

- (NSArray *)timeOrdered_historicalTransactionRecords
{
	NSMutableArray *list = [NSMutableArray new];
	for (std::pair<crypto::hash, light_wallet3::address_tx> pair: _wallet__ptr->address_txs()) {
		Monero_Bridge_HistoricalTransactionRecord *rec = [Monero_Bridge_HistoricalTransactionRecord new];
		{
			rec.amount = pair.second.m_amount;
			rec.isIncoming = pair.second.m_incoming;
			rec.height = pair.second.m_block_height;
			rec.mixin = pair.second.m_mixin;
			rec.timestampDate = [NSDate dateWithTimeIntervalSince1970: // TODO: is this correct?
				(NSTimeInterval)pair.second.m_timestamp
			];
			rec.unlockTime = pair.second.m_unlock_time;
			rec.mempool = pair.second.m_mempool;
			rec.txHash = [NSString stringWithUTF8String:
				string_tools::pod_to_hex(pair.second.m_tx_hash).c_str()
			];
			rec.paymentId = pair.second.m_payment_id_string.empty() == false ? [NSString stringWithUTF8String:pair.second.m_payment_id_string.c_str()] : nil;
		}
		[list addObject:rec];
	}
	{
		[list sortUsingComparator:^NSComparisonResult(
			Monero_Bridge_HistoricalTransactionRecord *_Nonnull obj1,
			Monero_Bridge_HistoricalTransactionRecord *_Nonnull obj2
		) {
			return [obj2.timestampDate compare:obj1.timestampDate];
		}];
	}
	return list;
}

- (void)new_serializedSignedTransactionWithTo_address:(NSString * __nonnull)to_address
								  amount_float_string:(NSString * __nonnull)amount_float_NSString
										   payment_id:(NSString * __nullable)optl__payment_id_NSString
											 priority:(uint32_t)simple_priority // this must be a number between (not including) 0 and 5
												   fn:(void(^ __nonnull)(NSString * __nullable errStr,
																		 NSString * __nullable serializedSignedTransactionString
																		 )
													   )fn
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		NSString *capitalized_errStr = [NSString stringWithFormat:@"%@%@", [[errStr substringToIndex:1] uppercaseString], [errStr substringFromIndex:1]];
		fn(
		   capitalized_errStr, // because errors are often passed lowercased
		   //
		   nil
	   );
	};
	//
	if (!_wallet__ptr || !self.hasLWBeenInitialized) {
		NSAssert(false, @"nil _wallet__ptr || !self.hasLWBeenInitialized");
		_doFn_withErrStr(NSLocalizedString(@"An application error has occurred", nil));
		return;
	}
	//
	void (^ getRandomOuts__block)(NSArray * _Nonnull amountStrings, uint32_t count, NSValue *promiseInValue, void(^ cb)(NSString * _Nullable errStr_orNil, NSString * _Nullable response_jsonString, NSValue *returned_promiseInValue)) = self.getRandomOuts__block;
	if (getRandomOuts__block == nil) {
		NSAssert(false, @"LightWallet3Wrapper.getRandomOuts__block must be set to construct a transaction");
		_doFn_withErrStr(NSLocalizedString(@"Code fault", nil));
		return;
	}
	//
	const std::string *optl__payment_id_string_ptr = nullptr;
	std::string payment_id_string; // to hold 
	if (optl__payment_id_NSString) {
		payment_id_string = std::string(optl__payment_id_NSString.UTF8String);
		optl__payment_id_string_ptr = &payment_id_string;
	}
	//
	tools::light_wallet3 *this_wallet__ptr = _wallet__ptr; // for capture
	std::function<bool(
		std::vector<std::vector<tools::wallet2::get_outs_entry>> &,
		const std::vector<size_t> &,
		size_t,
		monero_transfer_utils::get_random_outs_fn_RetVals &
	)> get_random_outs_fn = [
		getRandomOuts__block,
		this_wallet__ptr
	] (
		std::vector<std::vector<tools::wallet2::get_outs_entry>> &outs,
		const std::vector<size_t> &selected_transfers,
		size_t fake_outputs_count,
		monero_transfer_utils::get_random_outs_fn_RetVals &fn_retVals
	) -> bool {
		fn_retVals = {}; // initializing for consumer
		//
		NSMutableArray *amountStrings = [NSMutableArray new];
		{ // construct amounts for request
			std::vector<std::string> amounts;
			this_wallet__ptr->populate_amount_strings_for_get_random_outs(selected_transfers, amounts);
			for (std::string amount_string: amounts) {
				NSString *amountString = [NSString stringWithUTF8String:amount_string.c_str()];
				[amountStrings addObject:amountString];
			}
		}
  		uint32_t requested_outputs_count = this_wallet__ptr->requested_outputs_count(fake_outputs_count); // TODO: mymonero simple uses fake_outputs_count... use that instead?
		//
		// the following sequence must remain synchronous, therefore a promise is used; it must be given to objc-land
		auto promise = std::promise<light_wallet3::get_rand_outs_promise_ret_vals>();
		NSValue *promiseInValue = [NSValue valueWithBytes:&promise objCType:@encode(std::promise<int>)];
		getRandomOuts__block(
			amountStrings,
			requested_outputs_count,
			promiseInValue, // using an NSValue means ownership will not be transferred
			^(NSString *errStr_orNil, NSString *response_jsonString, NSValue *returned_promiseInValue)
			{
				light_wallet3::get_rand_outs_promise_ret_vals promise_ret_vals = {};
				{ // finalize
					bool block__did_error = errStr_orNil != nil ? true : false;
					if (block__did_error) {
						promise_ret_vals.did_error = block__did_error;
						promise_ret_vals.err_string = std::string(errStr_orNil.UTF8String);
					} else {
						promise_ret_vals.response_json_string = std::string(response_jsonString.UTF8String);
					}
				}
				std::promise<light_wallet3::get_rand_outs_promise_ret_vals> returned_promise;
				{ // finalize
					[returned_promiseInValue getValue:&returned_promise];
				}
				returned_promise.set_value(promise_ret_vals);
			}
		);
		std::future<light_wallet3::get_rand_outs_promise_ret_vals> future = promise.get_future();
		light_wallet3::get_rand_outs_promise_ret_vals ret_vals = future.get();
		if (ret_vals.did_error) {
			fn_retVals.did_error = true;
			fn_retVals.err_string = *ret_vals.err_string;
			return false;
		}
		light_wallet3_server_api::COMMAND_RPC_GET_RANDOM_OUTS::response ores;
		bool r = epee::serialization::load_t_from_json(ores, *ret_vals.response_json_string);
		if (!r) {
			return false;
		}
		RetVals_base populate_retVals;
		r = this_wallet__ptr->populate_from__get_random_outs(ores, outs, selected_transfers, fake_outputs_count, requested_outputs_count, populate_retVals);
		if (!r) {
			fn_retVals.did_error = true;
			fn_retVals.err_string = *populate_retVals.err_string;
			return false;
		}
		//
		return true;
	};
	monero_transfer_utils::CreateSignedTxs_RetVals retVals;
	BOOL r = _wallet__ptr->create_signed_transaction(
		std::string(to_address.UTF8String),
		std::string(amount_float_NSString.UTF8String),
		optl__payment_id_string_ptr,
		simple_priority,
		get_random_outs_fn,
		//
		retVals
	);
	if (retVals.did_error) {
		NSString *errStr = [NSString stringWithUTF8String:(*(retVals.err_string)).c_str()];
		_doFn_withErrStr(errStr);
		return;
	}
	NSAssert(r, @"Found unexpectedly didSucceed=false without an error"); // NOTE: unlike cpp code, asserting the positive here
	NSString *signedSerializedTransaction_NSString = nil; // TODO: get this from retVals		boost::optional<tools::wallet2::signed_tx_set> signed_tx_set;

	//
	fn(nil, signedSerializedTransaction_NSString);
}
@end
