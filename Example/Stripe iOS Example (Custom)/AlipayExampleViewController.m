//
//  AlipayExampleViewController.m
//  Stripe iOS Example (Custom)
//
//  Created by Joey Dong on 6/30/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "AlipayExampleViewController.h"

#import "BrowseExamplesViewController.h"

@interface AlipayExampleViewController ()

@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, weak) UILabel *waitingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) STPRedirectContext *redirectContext;

@end

@implementation AlipayExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    self.title = @"Sofort";

    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay with Alipay" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;
    [self.view addSubview:button];

    UILabel *label = [UILabel new];
    label.text = @"Waiting for payment authorization";
    [label sizeToFit];
    label.textColor = [UIColor grayColor];
    label.alpha = 0;
    [self.view addSubview:label];
    self.waitingLabel = label;

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), 100);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.payButton.frame) + padding*2);
    self.waitingLabel.center = CGPointMake(CGRectGetMidX(bounds),
                                           CGRectGetMaxY(self.activityIndicator.frame) + padding*2);
}

- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress {
    self.navigationController.navigationBar.userInteractionEnabled = !paymentInProgress;
    self.payButton.enabled = !paymentInProgress;
    [UIView animateWithDuration:0.2 animations:^{
        self.waitingLabel.alpha = paymentInProgress ? 1 : 0;
    }];
    if (paymentInProgress) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)pay {
    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    [self updateUIForPaymentInProgress:YES];
    STPSourceParams *sourceParams = [[STPSourceParams alloc] init];
    sourceParams.rawTypeString = @"alipay";
    sourceParams.amount = @1000;
    sourceParams.currency = @"usd";
    sourceParams.redirect = @{
                              @"return_url": @"payments-example://stripe-redirect"
                              };
    sourceParams.additionalAPIParameters = @{
                                             @"access_info": @{
                                                     @"channel": @"ALIPAYAPP"
                                                     }
                                             };

    [[STPAPIClient sharedClient] createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            // In order to use STPRedirectContext, you'll need to set up
            // your app delegate to forward URLs to the Stripe SDK.
            // See `[Stripe handleStripeURLCallback:]`
            self.redirectContext = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
                [[STPAPIClient sharedClient] startPollingSourceWithId:sourceID
                                                         clientSecret:clientSecret
                                                              timeout:10
                                                           completion:^(STPSource *source, NSError *error) {
                                                               [self updateUIForPaymentInProgress:NO];
                                                               if (error) {
                                                                   [self.delegate exampleViewController:self didFinishWithError:error];
                                                               } else {
                                                                   switch (source.status) {
                                                                       case STPSourceStatusChargeable:
                                                                       case STPSourceStatusConsumed:
                                                                           [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
                                                                           break;
                                                                       case STPSourceStatusCanceled:
                                                                           [self.delegate exampleViewController:self didFinishWithMessage:@"Payment failed"];
                                                                           break;
                                                                       case STPSourceStatusPending:
                                                                       case STPSourceStatusFailed:
                                                                       case STPSourceStatusUnknown:
                                                                           [self.delegate exampleViewController:self didFinishWithMessage:@"Order received"];
                                                                           break;
                                                                   }
                                                               }
                                                               self.redirectContext = nil;
                                                           }];
            }];
            [self.redirectContext startRedirectFlowFromViewController:self];
        }
    }];
}
#pragma clang diagnostic pop

@end
