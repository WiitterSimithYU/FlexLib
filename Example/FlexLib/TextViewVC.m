/**
 * Copyright (c) 2017-present, zhenglibao, Inc.
 * email: 798393829@qq.com
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */



#import "TextViewVC.h"

@interface TextViewVC ()
{
    UIScrollView* scroll;
}

@end

@implementation TextViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"TextView Demo";
    [self prepareInputs];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
