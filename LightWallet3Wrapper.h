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

@interface LightWallet3Wrapper: NSObject
//
// Imperatives - Lifecycle
- (id)init; // designated initializer
// then call one of
- (BOOL)setupWalletWith_mnemonicSeed:(NSString *)mnemonicSeed_NSString
					mnemonicLanguage:(NSString *)mnemonicLanguage_NSString;
- (BOOL)setupWalletWith_address:(NSString *)address_NSString
						viewkey:(NSString *)viewkey_NSString
					   spendkey:(NSString *)spendkey_NSString;
//
// Imperatives - Runtime
- (BOOL)ingestJSONString_addressInfo:(NSString *)response_jsonString or_didError:(BOOL)didError; // returns NO on parse err
- (BOOL)ingestJSONString_addressTxs:(NSString *)response_jsonString; // returns NO on parse err
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

- (NSString *)address;
- (NSString *)view_key__private;

@property (nonatomic, readonly) BOOL hasLWBeenInitialized; // is set to YES after successful call to any of the above -setupWalletWith_*


@end
