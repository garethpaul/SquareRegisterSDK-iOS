//
//  SCCAPIRequest.m
//  SquareRegisterSDK
//
//  Created by Mark Jen on 2/9/14.
//  Copyright (c) 2014 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SCCAPIRequest.h"
#import "SCCAPIRequest+Serialization.h"

#import "NSDictionary+SCCAdditions.h"
#import "NSError+SCCAdditions.h"
#import "SCCMoney.h"
#import "SCCMoney+Serialization.h"


NSString *__nonnull const SCCSDKVersion = @"2";
NSString *__nonnull const SCCAPIVersion = @"1";
NSString *__nonnull const SCCAPIURLSchemeBase = @"square-commerce";

NSString *__nonnull const SCCAPIRequestSDKVersionKey = @"sdk_version";
NSString *__nonnull const SCCAPIRequestClientIDKey = @"client_id";
NSString *__nonnull const SCCAPIRequestAmountMoneyKey = @"amount_money";
NSString *__nonnull const SCCAPIRequestCallbackURLKey = @"callback_url";
NSString *__nonnull const SCCAPIRequestLoginCodeKey = @"login_code";
NSString *__nonnull const SCCAPIRequestStateKey = @"state";
NSString *__nonnull const SCCAPIRequestMerchantIDKey = @"merchant_id";
NSString *__nonnull const SCCAPIRequestNotesKey = @"notes";
NSString *__nonnull const SCCAPIRequestOptionsKey = @"options";
NSString *__nonnull const SCCAPIRequestOptionsSupportedTenderTypesKey = @"supported_tender_types";
NSString *__nonnull const SCCAPIRequestOptionsClearDefaultFeesKey = @"clear_default_fees";
NSString *__nonnull const SCCAPIRequestOptionsAutoReturnKey = @"auto_return";
NSString *__nonnull const SCCAPIRequestOptionsTenderTypeStringCard = @"CREDIT_CARD";


@implementation SCCAPIRequest

#pragma mark - Class Methods

static NSString *__nullable APIClientID = nil;

+ (void)setClientID:(nullable NSString *)clientID;
{
    APIClientID = clientID;
}

#pragma mark - Class Methods - Private

+ (nullable NSString *)_clientID;
{
    return APIClientID;
}

+ (nonnull NSString *)_URLScheme;
{
    static NSString *URLScheme;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URLScheme = [NSString stringWithFormat:@"%@-v%@", SCCAPIURLSchemeBase, SCCAPIVersion];
    });
    return URLScheme;
}

#pragma mark - Initialization

+ (nullable instancetype)requestWithCallbackURL:(nonnull NSURL *)callbackURL
                                         amount:(nonnull SCCMoney *)amount
                                 userInfoString:(nullable NSString *)userInfoString
                                     merchantID:(nullable NSString *)merchantID
                                          notes:(nullable NSString *)notes
                           supportedTenderTypes:(SCCAPIRequestTenderTypes)supportedTenderTypes
                              clearsDefaultFees:(BOOL)clearsDefaultFees
                returnAutomaticallyAfterPayment:(BOOL)autoreturn
                                          error:(out NSError *__nullable *__nullable)error;
{
    if (![self.class _clientID].length) {
        if (error) {
            *error = [NSError SCC_missingRequestClientIDError];
        }
        return nil;
    }

    if (!amount || amount.amountCents < 0) {
        if (error) {
            *error = [NSError SCC_invalidRequestAmountError];
        }
        return nil;
    }

    if (!callbackURL.scheme.length) {
        if (error) {
            *error = [NSError SCC_invalidRequestCallbackURLError];
        }
        return nil;
    }

    return [[self alloc] initWithClientID:(NSString *__nonnull)[self.class _clientID]
                              callbackURL:callbackURL
                                   amount:amount
                           userInfoString:userInfoString
                               merchantID:merchantID
                                    notes:notes
                     supportedTenderTypes:supportedTenderTypes
                        clearsDefaultFees:clearsDefaultFees
          returnAutomaticallyAfterPayment:autoreturn];
}

- (instancetype)initWithClientID:(nonnull NSString *)clientID
                     callbackURL:(nonnull NSURL *)callbackURL
                          amount:(nonnull SCCMoney *)amount
                  userInfoString:(nullable NSString *)userInfoString
                      merchantID:(nullable NSString *)merchantID
                           notes:(nullable NSString *)notes
            supportedTenderTypes:(SCCAPIRequestTenderTypes)supportedTenderTypes
               clearsDefaultFees:(BOOL)clearsDefaultFees
 returnAutomaticallyAfterPayment:(BOOL)autoreturn;
{
    NSAssert(callbackURL.scheme.length, @"Callback URL must be specified and have a scheme.");
    NSAssert(amount && amount.amountCents >= 0, @"SCCMoney amount must be specified.");

    self = [super init];
    if (!self) {
        return nil;
    }

    _clientID = [clientID copy];
    _callbackURL = callbackURL;
    _amount = [amount copy];
    _userInfoString = [userInfoString copy];
    _merchantID = [merchantID copy];
    _notes = [notes copy];
    _supportedTenderTypes = supportedTenderTypes;
    _clearsDefaultFees = clearsDefaultFees;
    _returnsAutomaticallyAfterPayment = autoreturn;

    return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(nullable id)object;
{
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[SCCAPIRequest class]]) {
        return NO;
    }

    return [self isEqualToAPIRequest:object];
}

- (NSUInteger)hash;
{
    NSUInteger const hashOfRequiredFields = self.clientID.hash ^ self.callbackURL.hash ^ self.amount.hash;
    NSUInteger const hashOfOptionalFields = self.userInfoString.hash ^ self.merchantID.hash ^ self.notes.hash;
    NSUInteger const hashOfScalarFields = (NSUInteger)self.supportedTenderTypes ^ (NSUInteger)self.clearsDefaultFees ^ (NSUInteger)self.returnsAutomaticallyAfterPayment;

    return hashOfRequiredFields ^ hashOfOptionalFields ^ hashOfScalarFields;
}

- (nonnull NSString *)description;
{
    // Due to the number of fields, the description includes only the required ones.
    return [NSString stringWithFormat:@"<%@: %p> { clientID: %@, callbackURL: %@, amount: %@ }",
        NSStringFromClass(self.class),
        self,
        self.clientID,
        self.callbackURL,
        self.amount];
}

#pragma mark - NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone;
{
    // As an immutable value type, self may be returned in place of a copy.
    return self;
}

#pragma mark - Public Methods

- (BOOL)isEqualToAPIRequest:(nullable SCCAPIRequest *)request;
{
    if (!request) {
        return NO;
    }

    // The following properties are required and cannot be nil.
    if (![self.clientID isEqualToString:(NSString *__nonnull)request.clientID] ||
        ![self.callbackURL isEqual:request.callbackURL] ||
        ![self.amount isEqualToSCCMoney:request.amount]) {
        return NO;
    }

    // The following properties are scalar.
    if (!(self.supportedTenderTypes == request.supportedTenderTypes) ||
        !(self.clearsDefaultFees == request.clearsDefaultFees) ||
        !(self.returnsAutomaticallyAfterPayment == request.returnsAutomaticallyAfterPayment)) {
        return NO;
    }

    // The following properties are nullable and require additional verification.
    BOOL const haveEqualUserInfoStrings = (!self.userInfoString && !request.userInfoString) || [self.userInfoString isEqual:request.userInfoString];
    BOOL const haveEqualMerchantIDs = (!self.merchantID && !request.merchantID) || [self.merchantID isEqual:request.merchantID];
    BOOL const haveEqualNotes = (!self.notes && !request.notes) || [self.notes isEqual:request.notes];

    if (!(haveEqualUserInfoStrings && haveEqualMerchantIDs && haveEqualNotes)) {
        return NO;
    }

    return YES;
}

@end


@implementation SCCAPIRequest (Serialization)

- (nullable NSURL *)APIRequestURLWithError:(out NSError *__nullable *__nullable)error;
{
    NSMutableDictionary *const data = [NSMutableDictionary dictionary];
    [data setObject:SCCSDKVersion forKey:SCCAPIRequestSDKVersionKey];
    [data setObject:self.clientID forKey:SCCAPIRequestClientIDKey];

    [data SCC_setSafeObject:self.amount.requestDictionaryRepresentation forKey:SCCAPIRequestAmountMoneyKey];
    [data SCC_setSafeObject:self.callbackURL.absoluteString forKey:SCCAPIRequestCallbackURLKey];
    [data SCC_setSafeObject:self.userInfoString forKey:SCCAPIRequestStateKey];
    [data SCC_setSafeObject:self.merchantID forKey:SCCAPIRequestMerchantIDKey];
    [data SCC_setSafeObject:self.notes forKey:SCCAPIRequestNotesKey];

    NSMutableDictionary *const options = [NSMutableDictionary dictionary];
    NSArray *const supportedTenderTypes = NSArrayOfTenderTypeStringsFromSCCAPIRequestTenderTypes(self.supportedTenderTypes);
    [options SCC_setSafeObject:supportedTenderTypes forKey:SCCAPIRequestOptionsSupportedTenderTypesKey];
    [options SCC_setSafeObject:@(self.clearsDefaultFees) forKey:SCCAPIRequestOptionsClearDefaultFeesKey];
    [options SCC_setSafeObject:@(self.returnsAutomaticallyAfterPayment) forKey:SCCAPIRequestOptionsAutoReturnKey];
    if (options.count) {
        [data SCC_setSafeObject:options forKey:SCCAPIRequestOptionsKey];
    }

    NSData *const JSONData = [NSJSONSerialization dataWithJSONObject:data options:(NSJSONWritingOptions)0 error:NULL];
    if (JSONData.length == 0) {
        if (error) {
            *error = [NSError SCC_unableToGenerateRequestJSONError];
        }
        return nil;
    }

    // The query parameter character set is everything allowed in the entire query term minus reserved characters.
    NSMutableCharacterSet *const queryParameterCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [queryParameterCharacterSet removeCharactersInString:@":/?#[]@!$&'()*+,;="];

    NSString *const queryDataParameter = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    NSString *const encodedString = [queryDataParameter stringByAddingPercentEncodingWithAllowedCharacters:queryParameterCharacterSet];
    NSString *const URLString = [NSString stringWithFormat:@"%@://payment/create?data=%@", [[self class] _URLScheme], encodedString];

    return [NSURL URLWithString:URLString];
}

@end


NSArray *__nonnull NSArrayOfTenderTypeStringsFromSCCAPIRequestTenderTypes(SCCAPIRequestTenderTypes tenderTypes)
{
    NSMutableArray *const arrayOfTenderTypes = [NSMutableArray array];

    if (tenderTypes & SCCAPIRequestTenderTypeCard) {
        [arrayOfTenderTypes addObject:SCCAPIRequestOptionsTenderTypeStringCard];
    }

    return arrayOfTenderTypes;
}
