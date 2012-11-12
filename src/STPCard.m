//
//  STPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "STPCard.h"
#import "StripeError.h"

@interface STPCard ()
{
    NSString *last4;
    NSString *type;
    NSString *fingerprint;
}

+ (BOOL)isLuhnValidString:(NSString *)number;
+ (BOOL)isNumericOnlyString:(NSString *)aString;
+ (void)handleValidationErrorForParameter:(NSString *)parameter error:(NSError **)outError;
+ (NSError *)createErrorWithMessage:(NSString *)userMessage parameter:(NSString *)parameter cardErrorCode:(NSString *)cardErrorCode devErrorMessage:(NSString *)devMessage;
+ (NSInteger)currentYear;
+ (BOOL)isExpiredMonth:(NSInteger)month andYear:(NSInteger)year;
@end


@implementation STPCard
@synthesize number, expMonth, expYear, cvc, name, addressLine1, addressLine2, addressZip, addressCity, addressState, addressCountry, country, object, fingerprint;
@dynamic last4, type;

#pragma mark Private Helpers
+ (BOOL)isLuhnValidString:(NSString *)number
{
    BOOL isOdd = true;
    NSInteger sum = 0;

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    for (NSInteger index = [number length] - 1; index >= 0; index--)
    {
        NSString *digit = [number substringWithRange:NSMakeRange(index, 1)];
        NSNumber *digitNumber = [numberFormatter numberFromString:digit];
        if (digitNumber == NULL)
            return NO;
        NSInteger digitInteger = [digitNumber intValue];
        isOdd = !isOdd;
        if (isOdd)
            digitInteger *= 2;

        if (digitInteger > 9)
            digitInteger -= 9;

        sum += digitInteger;
    }

    if (sum % 10 == 0)
        return YES;
    else
        return NO;
}

+ (BOOL)isNumericOnlyString:(NSString *)aString
{
    NSCharacterSet *numericOnly = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *aStringSet = [NSCharacterSet characterSetWithCharactersInString:aString];

    return [numericOnly isSupersetOfSet: aStringSet];
}

+ (BOOL)isExpiredMonth:(NSInteger)month andYear:(NSInteger)year
{
    NSDate *now = [NSDate date];

    // Cards expire at end of month
    month = month + 1;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:1];
    NSDate *expiryDate = [calendar dateFromComponents:components];
    return ([expiryDate compare:now] == NSOrderedAscending);
}

+ (NSInteger)currentYear
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSYearCalendarUnit fromDate:[NSDate date]];
    return [components year];
}

+ (void)handleValidationErrorForParameter:(NSString *)parameter error:(NSError **)outError
{
    if (outError != NULL)
    {
        if ([parameter isEqualToString:@"number"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidNumberUserMessage parameter:parameter cardErrorCode:STPInvalidNumber devErrorMessage:@"Card number must be between 10 and 19 digits long and Luhn valid."];
        else if ([parameter isEqualToString:@"cvc"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidCVCUserMessage parameter:parameter cardErrorCode:STPInvalidCVC devErrorMessage:@"Card CVC must be numeric, 3 digits for Visa, Discover, MasterCard, JCB, and Discover cards, and 4 digits for American Express cards."];
        else if ([parameter isEqualToString:@"expMonth"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidExpMonthUserMessage parameter:parameter cardErrorCode:STPInvalidExpMonth devErrorMessage:@"expMonth must be less than 13"];
        else if ([parameter isEqualToString:@"expYear"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidExpYearUserMessage parameter:parameter cardErrorCode:STPInvalidExpYear devErrorMessage:@"expYear must be this year or a year in the future"];
    }
}

+ (NSError *)createErrorWithMessage:(NSString *)userMessage parameter:(NSString *)parameter cardErrorCode:(NSString *)cardErrorCode devErrorMessage:(NSString *)devMessage
{
    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : userMessage,
                                         STPErrorParameterKey : parameter,
                                          STPCardErrorCodeKey : cardErrorCode,
                                           STPErrorMessageKey : devMessage };


    return [[NSError alloc] initWithDomain:StripeDomain
                                      code:STPCardError
                                  userInfo:userInfoDict];
}

#pragma mark Public Interface
- (id)init
{
    if (self = [super init])
        object = @"card";
    return self;
}

- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary
{
    if (self = [self init])
    {
        number = [attributeDictionary valueForKey:@"number"];
        expMonth = [[attributeDictionary objectForKey:@"expMonth"] intValue];
        expYear = [[attributeDictionary objectForKey:@"expYear"] intValue];
        cvc = [attributeDictionary objectForKey:@"cvc"];
        name = [attributeDictionary objectForKey:@"name"];
        addressLine1 = [attributeDictionary objectForKey:@"addressLine1"];
        addressLine2 = [attributeDictionary objectForKey:@"addressLine2"];
        addressCity = [attributeDictionary objectForKey:@"addressCity"];
        addressState = [attributeDictionary objectForKey:@"addressState"];
        addressZip = [attributeDictionary objectForKey:@"addressZip"];
        addressCountry = [attributeDictionary objectForKey:@"addressCountry"];
        object = [attributeDictionary objectForKey:@"object"];
        last4 = [attributeDictionary objectForKey:@"last4"];
        type = [attributeDictionary objectForKey:@"type"];
        fingerprint = [attributeDictionary objectForKey:@"fingerprint"];
        country = [attributeDictionary objectForKey:@"country"];
    }
    return self;
}

- (NSString *)last4
{
    if (last4)
        return last4;
    else if ([self number])
        return [number substringFromIndex:([number length] - 4)];
    else
        return NULL;
}

- (NSString *)type
{
    if (type)
        return type;
    else if ([self number])
    {
        NSString *firstTwoDigits = [number substringToIndex:2];
        NSString *firstDigit = [number substringToIndex:1];
        if ([firstTwoDigits isEqualToString:@"34"] || [firstTwoDigits isEqualToString:@"37"])
            return @"American Express";
        else if ([firstTwoDigits isEqualToString:@"60"] ||
                 [firstTwoDigits isEqualToString:@"62"] ||
                 [firstTwoDigits isEqualToString:@"64"] ||
                 [firstTwoDigits isEqualToString:@"65"])
            return @"Discover";
        else if ([firstTwoDigits isEqualToString:@"35"])
            return @"JCB";
        else if ([firstTwoDigits isEqualToString:@"30"] ||
                 [firstTwoDigits isEqualToString:@"36"] ||
                 [firstTwoDigits isEqualToString:@"38"] ||
                 [firstTwoDigits isEqualToString:@"39"])
            return @"Diners Club";
         else if ([firstDigit isEqualToString:@"4"])
             return @"Visa";
         else if ([firstDigit isEqualToString:@"5"])
             return @"MasterCard";
        else
            return @"Unknown";
    }
    else
        return NULL;
}

- (BOOL)validateNumber:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == NULL)
    {
        [STPCard handleValidationErrorForParameter:@"number" error:outError];
        return NO;
    }

    NSError *regexError = NULL;
    NSString *ioValueString = (NSString *)*ioValue;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[\\s+|-]"
                                    options:NSRegularExpressionCaseInsensitive
                                      error:&regexError];

    NSString *rawNumber = [regex stringByReplacingMatchesInString:ioValueString options:0 range:NSMakeRange(0, [ioValueString length]) withTemplate:@""];

    if (rawNumber == nil || rawNumber.length < 10 || rawNumber.length > 19 || ![STPCard isLuhnValidString:rawNumber])
    {
        [STPCard handleValidationErrorForParameter:@"number" error:outError];
        return NO;
    }
    return YES;
}

- (BOOL)validateCvc:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == NULL)
    {
        [STPCard handleValidationErrorForParameter:@"number" error:outError];
        return NO;
    }
    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *cardType = [self type];
    BOOL validLength = ((cardType == NULL && [ioValueString length] >= 3 && [ioValueString length] <= 4) ||
                         ([cardType isEqualToString:@"American Express"] && [ioValueString length] == 4) ||
                         (![cardType isEqualToString:@"American Express"] && [ioValueString length] == 3));


    if (![STPCard isNumericOnlyString:ioValueString] || !validLength)
    {
        [STPCard handleValidationErrorForParameter:@"cvc" error:outError];
        return NO;
    }
    return YES;
}

- (BOOL)validateExpMonth:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == NULL)
    {
        [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
        return NO;
    }
    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger expMonthInt = [ioValueString integerValue];

    if ((![STPCard isNumericOnlyString:ioValueString] || expMonthInt > 12 || expMonthInt < 1))
    {
        [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
        return NO;
    }
    else if ([self expYear] && [STPCard isExpiredMonth:expMonthInt andYear:[self expYear]])
    {
        NSInteger currentYear = [STPCard currentYear];
        // If the year is in the past, this is actually a problem with the expYear parameter, but it still means this month is not a valid month. This is pretty rare - it means someone set expYear on the card without validating it
        if (currentYear > [self expYear])
            [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
        else
            [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
        return NO;
    }
    return YES;
}

- (BOOL)validateExpYear:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == NULL)
    {
        [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
        return NO;
    }
    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger expYearInt = [ioValueString integerValue];

    if ((![STPCard isNumericOnlyString:ioValueString] || expYearInt < [STPCard currentYear]))
    {
        [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
        return NO;
    }
    else if ([self expMonth] && [STPCard isExpiredMonth:[self expMonth] andYear:expYearInt])
    {
        [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
        return NO;
    }
    return YES;

}

- (BOOL)validateCardReturningError:(NSError **)outError;
{
    // Order matters here
    NSString *numberRef = [self number];
    NSString *expMonthRef = [NSString stringWithFormat:@"%u", [self expMonth]];
    NSString *expYearRef = [NSString stringWithFormat:@"%u", [self expYear]];
    NSString *cvcRef = [self cvc];

    // Make sure expMonth, expYear, and number are set.  Validate CVC if it is provided
    return [self validateNumber:&numberRef error:outError] &&
           [self validateExpYear:&expYearRef error:outError] &&
           [self validateExpMonth:&expMonthRef error:outError] && (cvcRef == NULL || [self validateCvc:&cvcRef error:outError]);
}
@end