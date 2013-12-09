//
//  PKPaymentField.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
#define DarkGreyColor RGB(0,0,0)
#define RedColor RGB(253,0,17)
#define DefaultBoldFont [UIFont boldSystemFontOfSize:17]

#define kPKViewPlaceholderViewAnimationDuration 0.25

#define kPKViewCardExpiryFieldStartX 84 + 200
#define kPKViewCardCVCFieldStartX 177 + 200

#define kPKViewCardExpiryFieldEndX 84
#define kPKViewCardCVCFieldEndX 177

#import <QuartzCore/QuartzCore.h>
#import "PKView.h"
#import "PKTextField.h"

@interface PKView () <UITextFieldDelegate> {
@private
    BOOL isInitialState;
    BOOL isValidState;
}

@property (nonatomic, readwrite) UIView *opaqueOverGradientView;

- (void)setup;
- (void)setupPlaceholderView;
- (void)setupCardNumberField;
- (void)setupCardExpiryField;
- (void)setupCardCVCField;

- (void)stateCardNumber;
- (void)stateMeta;
- (void)stateCardCVC;

- (void)setPlaceholderViewImage:(UIImage *)image;
- (void)setPlaceholderToCVC;
- (void)setPlaceholderToCardType;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardNumberFieldShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardCVCShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString;

- (void)checkValid;
- (void)textFieldIsValid:(UITextField *)textField;
- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors;
@end

@implementation PKView

bool _shouldHaveFocus = NO;

@synthesize innerView, opaqueOverGradientView, cardNumberField,
            cardExpiryField, cardCVCField,
            placeholderView, delegate;

- (instancetype)initWithFrame:(CGRect)frame andShouldHaveFocus:(BOOL)passedBool {
    
    self = [super initWithFrame:frame];
    if (self) {
        _shouldHaveFocus = passedBool;
        [self setup];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    isInitialState = YES;
    isValidState   = NO;
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 46);
    self.backgroundColor = [UIColor clearColor];
    
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:self.backgroundImageView];
    
    self.innerView = [[UIView alloc] initWithFrame:CGRectMake(40, 0, self.frame.size.width - 40, self.frame.size.height)];
    self.innerView.clipsToBounds = YES;
    self.innerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self setupPlaceholderView];
    [self setupCardNumberField];
    [self setupCardExpiryField];
    [self setupCardCVCField];
    
    [self.innerView addSubview:cardNumberField];
    [self.innerView addSubview:cardExpiryField];
    [self.innerView addSubview:cardCVCField];
    
    self.opaqueOverGradientView = [[UIView alloc] initWithFrame:CGRectMake(40, 15, 10, 20)];
    self.opaqueOverGradientView.backgroundColor = [UIColor starbucksWhite];
    
    [self addSubview:self.innerView];
    [self addSubview:self.opaqueOverGradientView];
    [self addSubview:placeholderView];
    
    if (_shouldHaveFocus)
        [self stateCardNumber];
}


- (void)setupPlaceholderView
{
    UIImage *pImage = [UIImage imageNamed:@"placeholder"];
    placeholderView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 0, 32, self.bounds.size.height)];
    placeholderView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    placeholderView.contentMode = UIViewContentModeScaleAspectFit;
    placeholderView.backgroundColor = [UIColor clearColor];
    placeholderView.image = pImage;
    
    CALayer *clip = [CALayer layer];
    clip.frame = CGRectMake(32, 0, 4, 20);
    clip.backgroundColor = [UIColor clearColor].CGColor;
    [placeholderView.layer addSublayer:clip];
}

- (void)setupCardNumberField
{
    cardNumberField = [[PKTextField alloc] initWithFrame:CGRectMake(12,0,self.bounds.size.width,self.bounds.size.height)];
    cardNumberField.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    cardNumberField.delegate = self;
    
    cardNumberField.placeholder = @"1234 5678 9012 3456";
    cardNumberField.keyboardType = UIKeyboardTypeNumberPad;
    cardNumberField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    cardNumberField.textColor = DarkGreyColor;
    cardNumberField.font = DefaultBoldFont;
    
    [cardNumberField.layer setMasksToBounds:YES];
}

- (void)setupCardExpiryField
{
    cardExpiryField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardExpiryFieldStartX,0,
                                                                    60,self.bounds.size.height)];
    cardExpiryField.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    cardExpiryField.delegate = self;
    
    cardExpiryField.placeholder = @"MM/YY";
    cardExpiryField.keyboardType = UIKeyboardTypeNumberPad;
    cardExpiryField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    cardExpiryField.textColor = DarkGreyColor;
    cardExpiryField.font = DefaultBoldFont;
    
    [cardExpiryField.layer setMasksToBounds:YES];
}

- (void)setupCardCVCField
{
    cardCVCField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardCVCFieldStartX,0,
                                                                 55,self.bounds.size.height)];
    cardCVCField.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    cardCVCField.delegate = self;
    
    cardCVCField.placeholder = @"CVC";
    cardCVCField.keyboardType = UIKeyboardTypeNumberPad;
    cardCVCField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    cardCVCField.textColor = DarkGreyColor;
    cardCVCField.font = DefaultBoldFont;
    
    [cardCVCField.layer setMasksToBounds:YES];
}

// Accessors

- (PKCardNumber*)cardNumber
{
    return [PKCardNumber cardNumberWithString:cardNumberField.text];
}

- (PKCardExpiry*)cardExpiry
{
    return [PKCardExpiry cardExpiryWithString:cardExpiryField.text];
}

- (PKCardCVC*)cardCVC
{
    return [PKCardCVC cardCVCWithString:cardCVCField.text];
}

// State

- (void)stateCardNumber
{
    if (!isInitialState) {
        // Animate left
        isInitialState = YES;
        
        [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             opaqueOverGradientView.alpha = 0.0;
                         } completion:^(BOOL finished) {}];
        [UIView animateWithDuration:0.400
                              delay:0
                            options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             cardExpiryField.frame = CGRectMake(kPKViewCardExpiryFieldStartX,
                                                                cardExpiryField.frame.origin.y,
                                                                cardExpiryField.frame.size.width,
                                                                cardExpiryField.frame.size.height);
                             cardCVCField.frame = CGRectMake(kPKViewCardCVCFieldStartX,
                                                             cardCVCField.frame.origin.y,
                                                             cardCVCField.frame.size.width,
                                                             cardCVCField.frame.size.height);
                             cardNumberField.frame = CGRectMake(12,
                                                                cardNumberField.frame.origin.y,
                                                                cardNumberField.frame.size.width,
                                                                cardNumberField.frame.size.height);
                         }
                         completion:^(BOOL completed) {
                             [cardExpiryField removeFromSuperview];
                             [cardCVCField removeFromSuperview];
                         }];
    }
    
    [self.cardNumberField becomeFirstResponder];
}

- (void)stateMeta
{
    isInitialState = NO;
    
    CGSize cardNumberSize = [self.cardNumber.formattedString sizeWithFont:DefaultBoldFont];
    CGSize lastGroupSize = [self.cardNumber.lastGroup sizeWithFont:DefaultBoldFont];
    CGFloat frameX = self.cardNumberField.frame.origin.x - (cardNumberSize.width - lastGroupSize.width);
    
    [UIView animateWithDuration:0.05 delay:0.35 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         opaqueOverGradientView.alpha = 1.0;
                     } completion:^(BOOL finished) {}];
    [UIView animateWithDuration:0.400 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        cardExpiryField.frame = CGRectMake(kPKViewCardExpiryFieldEndX,
                                           cardExpiryField.frame.origin.y,
                                           cardExpiryField.frame.size.width,
                                           cardExpiryField.frame.size.height);
        cardCVCField.frame = CGRectMake(kPKViewCardCVCFieldEndX,
                                        cardCVCField.frame.origin.y,
                                        cardCVCField.frame.size.width,
                                        cardCVCField.frame.size.height);
        cardNumberField.frame = CGRectMake(frameX,
                                           cardNumberField.frame.origin.y,
                                           cardNumberField.frame.size.width,
                                           cardNumberField.frame.size.height);
    } completion:nil];
    
    [self addSubview:placeholderView];
    [self.innerView addSubview:cardExpiryField];
    [self.innerView addSubview:cardCVCField];
    [cardExpiryField becomeFirstResponder];
}

- (void)stateCardCVC
{
    [cardCVCField becomeFirstResponder];
}

- (BOOL)isValid
{
    PKCardType cardType = [[PKCardNumber cardNumberWithString:cardNumberField.text] cardType];
    return [self.cardNumber isValid] && [self.cardExpiry isValid] && [self.cardCVC isValidWithType:cardType];
}

- (PKCard*)card
{
    PKCard* card    = [[PKCard alloc] init];
    card.number     = [self.cardNumber string];
    card.cvc        = [self.cardCVC string];
    card.expMonth   = [self.cardExpiry month];
    card.expYear    = [self.cardExpiry year];
    
    return card;
}

- (void)setPlaceholderViewImage:(UIImage *)image
{
    if(![placeholderView.image isEqual:image]) {
        __block __weak UIView *previousPlaceholderView = placeholderView;
        [UIView animateWithDuration:kPKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             placeholderView.layer.opacity = 0.0;
             placeholderView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2);
         } completion:^(BOOL finished) {
             [previousPlaceholderView removeFromSuperview];
         }];
        placeholderView = nil;
        
        [self setupPlaceholderView];
        placeholderView.image = image;
        placeholderView.layer.opacity = 0.0;
        placeholderView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
        [self insertSubview:placeholderView belowSubview:previousPlaceholderView];
        [UIView animateWithDuration:kPKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             placeholderView.layer.opacity = 1.0;
             placeholderView.layer.transform = CATransform3DIdentity;
         } completion:^(BOOL finished) {}];
    }
}

- (void)setPlaceholderToCVC
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:cardNumberField.text];
    PKCardType cardType      = [cardNumber cardType];
    
    if (cardType == PKCardTypeAmex) {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc-amex"]];
    } else {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc"]];
    }
}

- (void)setPlaceholderToCardType
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:cardNumberField.text];
    PKCardType cardType      = [cardNumber cardType];
    NSString* cardTypeName   = @"placeholder";
    
    switch (cardType) {
        case PKCardTypeAmex:
            cardTypeName = @"amex";
            break;
        case PKCardTypeDinersClub:
            cardTypeName = @"invalidCard";
//            cardTypeName = @"diners";
            break;
        case PKCardTypeDiscover:
            cardTypeName = @"discover";
            break;
        case PKCardTypeJCB:
            cardTypeName = @"invalidCard";
//            cardTypeName = @"jcb";
            break;
        case PKCardTypeMasterCard:
            cardTypeName = @"mastercard";
            break;
        case PKCardTypeVisa:
            cardTypeName = @"visa";
            break;
        default:
            break;
    }

    [self setPlaceholderViewImage:[UIImage imageNamed:cardTypeName]];
}

// Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:cardCVCField]) {
        [self setPlaceholderToCVC];
    } else {
        [self setPlaceholderToCardType];
    }
    
    if ([textField isEqual:cardNumberField] && !isInitialState) {
        [self stateCardNumber];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    if ([textField isEqual:cardNumberField]) {
        return [self cardNumberFieldShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    if ([textField isEqual:cardExpiryField]) {
        return [self cardExpiryShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    if ([textField isEqual:cardCVCField]) {
        return [self cardCVCShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    return YES;
}

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PKTextField *)textField
{
    if (textField == self.cardCVCField)
        [self.cardExpiryField becomeFirstResponder];
    else if (textField == self.cardExpiryField)
        [self stateCardNumber];
}

- (BOOL)cardNumberFieldShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [cardNumberField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:resultString];
    
    if ( ![cardNumber isPartiallyValid] )
        return NO;
    
    if (replacementString.length > 0) {
        cardNumberField.text = [cardNumber formattedStringWithTrail];
    } else {
        cardNumberField.text = [cardNumber formattedString];
    }
    
    [self setPlaceholderToCardType];
    
    BOOL cardNumberIsValidLength = [cardNumber isValidLength];
    
    if ([cardNumber isValid]) {
        [self textFieldIsValid:cardNumberField];
        [self stateMeta];
        if([self.delegate respondsToSelector:@selector(paymentView:numberIsValid:)]) {
            [self.delegate paymentView:self numberIsValid:YES];
        }
        
    } else if (cardNumberIsValidLength && ![cardNumber isValidLuhn]) {
        [self textFieldIsInvalid:cardNumberField withErrors:YES];
        if([self.delegate respondsToSelector:@selector(paymentView:numberIsValid:)]) {
            [self.delegate paymentView:self numberIsValid:NO];
        }
        
    } else if (!cardNumberIsValidLength) {
        [self textFieldIsInvalid:cardNumberField withErrors:NO];
    }
    else {
        // Mod to prevent the use of Diner's Club and JCB cards - JS (07/15/13)
        PKCardType cardType = [cardNumber cardType];
        if (cardType == PKCardTypeJCB || cardType == PKCardTypeDinersClub || cardType == PKCardTypeUnknown) {
            [self textFieldIsInvalid:cardNumberField withErrors:YES];
        }
    }
    
    return NO;
}

- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [cardExpiryField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardExpiry *cardExpiry = [PKCardExpiry cardExpiryWithString:resultString];
    
    if (![cardExpiry isPartiallyValid]) return NO;
    
    // Only support shorthand year
    if ([cardExpiry formattedString].length > 5) return NO;
    
    if (replacementString.length > 0) {
        cardExpiryField.text = [cardExpiry formattedStringWithTrail];
    } else {
        cardExpiryField.text = [cardExpiry formattedString];
    }
    
    if ([cardExpiry isValid]) {
        [self textFieldIsValid:cardExpiryField];
        [self stateCardCVC];
        
    } else if ([cardExpiry isValidLength] && ![cardExpiry isValidDate]) {
        [self textFieldIsInvalid:cardExpiryField withErrors:YES];
    } else if (![cardExpiry isValidLength]) {
        [self textFieldIsInvalid:cardExpiryField withErrors:NO];
    }
    
    return NO;
}

- (BOOL)cardCVCShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [cardCVCField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardCVC *cardCVC = [PKCardCVC cardCVCWithString:resultString];
    PKCardType cardType = [[PKCardNumber cardNumberWithString:cardNumberField.text] cardType];
    
    // Restrict length
    if ( ![cardCVC isPartiallyValidWithType:cardType] ) return NO;
    
    // Strip non-digits
    cardCVCField.text = [cardCVC string];
    
    if ([cardCVC isValidWithType:cardType]) {
        [self textFieldIsValid:cardCVCField];
    } else {
        [self textFieldIsInvalid:cardCVCField withErrors:NO];
    }
    
    return NO;
}

// Validations

- (void)checkValid
{
    if ([self isValid] && !isValidState) {
        isValidState = YES;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:YES];
        }
        
    } else if (![self isValid] && isValidState) {
        isValidState = NO;
        
        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:NO];
        }
    }
}

- (void)textFieldIsValid:(UITextField *)textField {
    textField.textColor = DarkGreyColor;
    [self checkValid];
}

- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors {
    if (errors) {
        textField.textColor = RedColor;
    } else {
        textField.textColor = DarkGreyColor;        
    }

    [self checkValid];
}

@end