//
//  AlipayExampleViewController.h
//  Stripe iOS Example (Custom)
//
//  Created by Joey Dong on 6/30/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExampleViewControllerDelegate;

@interface AlipayExampleViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end
