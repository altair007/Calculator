//
//  main.m
//  Calculator
//
//  Created by   颜风 on 14-5-25.
//  Copyright (c) 2014年 Shadow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Calculator.h"

int main(int argc, const char * argv[])
{
    NSString * exprOc = @"2*6-95";
    NSLog(@"%@ = %g", exprOc, [Calculator calculate:exprOc]);
    return 0;
}