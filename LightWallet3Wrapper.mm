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
//
using namespace epee; // for string_tools
using namespace tools;
using namespace crypto;
using namespace cryptonote;
//
//
// Accessory Types - Implementation
//
//@implementation Monero_Bridge_SpentOutputDescription
//@end
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
	cryptonote::COMMAND_RPC_GET_ADDRESS_INFO::response ires;
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
	cryptonote::COMMAND_RPC_GET_ADDRESS_TXS::response ires;
	bool r = epee::serialization::load_t_from_json(ires, std::string(response_jsonString.UTF8String));
	if (!r) {
		return NO;
	}
	_wallet__ptr->ingest__get_address_txs(ires);
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
			rec.timestamp = pair.second.m_timestamp;
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
			uint64_t d = obj2.timestamp - obj1.timestamp;
			if (d == 0) {
				return NSOrderedSame;
			} else if (d > 0) {
				return NSOrderedDescending;
			}
			return NSOrderedAscending;
		}];
	}
	return list;
}

@end
